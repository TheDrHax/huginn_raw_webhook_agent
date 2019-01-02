module Agents
  class RawWebhookAgent < Agent
    include WebRequestConcern

    cannot_be_scheduled!
    cannot_receive_events!

    description do <<-MD
      The Raw Webhook Agent will create events by receiving webhooks from any source. In order to create events with this agent, make a POST request to:

      ```
         https://#{ENV['DOMAIN']}/users/#{user.id}/web_requests/#{id || ':id'}/#{options['secret'] || ':secret'}
      ```
      #{'The placeholder symbols above will be replaced by their values once the agent is saved.' unless id}

      # Options:

        * `secret` (required) - A token that the host will provide for authentication.
        * `expected_receive_period_in_days` (required) - How often you expect to receive
          events this way. Used to determine if the agent is working.
        * `verbs` - Comma-separated list of http verbs your agent will accept.
          For example, "post,get" will enable POST and GET requests. Defaults
          to "post".
        * `response` - The response message to the request. Defaults to 'Event Created'.
        * `response_headers` - An object with any custom response headers. (example: `{"Access-Control-Allow-Origin": "*"}`)
        * `code` - The response code to the request. Defaults to '201'. If the code is '301' or '302' the request will automatically be redirected to the url defined in "response".
        * `recaptcha_secret` - Setting this to a reCAPTCHA "secret" key makes your agent verify incoming requests with reCAPTCHA.  Don't forget to embed a reCAPTCHA snippet including your "site" key in the originating form(s).
        * `recaptcha_send_remote_addr` - Set this to true if your server is properly configured to set REMOTE_ADDR to the IP address of each visitor (instead of that of a proxy server).
      MD
    end

    event_description do
      <<-MD
        Events look like this:

        ```
        {
          "body": "...",
          "query": {
            "param1": "...",
            ...
          },
          "json": {
            "param1": "...",
            ...
          }
        }
        ```
      MD
    end

    def default_options
      { "secret" => "supersecretstring",
        "expected_receive_period_in_days" => 1
      }
    end

    def receive_web_request(request)
      params = request.params.except(:action, :controller, :agent_id, :user_id, :format)
      method = request.method_symbol.to_s

      # check the secret
      secret = params.delete('secret')
      return ["Not Authorized", 401] unless secret == interpolated['secret']

      # check the verbs
      verbs = (interpolated['verbs'] || 'post').split(/,/).map { |x| x.strip.downcase }.select { |x| x.present? }
      return ["Please use #{verbs.join('/').upcase} requests only", 401] unless verbs.include?(method)

      # check the code
      code = (interpolated['code'].presence || 201).to_i

      # check the reCAPTCHA response if required
      if recaptcha_secret = interpolated['recaptcha_secret'].presence
        recaptcha_response = params.delete('g-recaptcha-response') or
          return ["Not Authorized", 401]

        parameters = {
          secret: recaptcha_secret,
          response: recaptcha_response,
        }

        if boolify(interpolated['recaptcha_send_remote_addr'])
          parameters[:remoteip] = request.env['REMOTE_ADDR']
        end

        begin
          response = faraday.post('https://www.google.com/recaptcha/api/siteverify',
                                  parameters)
        rescue => e
          error "Verification failed: #{e.message}"
          return ["Not Authorized", 401]
        end

        JSON.parse(response.body)['success'] or
          return ["Not Authorized", 401]
      end

      payload = {
        "body" => request.raw_post(),
        "query" => request.query_parameters(),
        "json" => parse_json(request.raw_post())
      }

      create_event(payload: payload)

      if interpolated['response_headers'].presence
        [interpolated(params.merge(payload))['response'] || 'Event Created', code, "text/plain", interpolated['response_headers'].presence]
      else
        [interpolated(params.merge(payload))['response'] || 'Event Created', code]
      end
    end

    def parse_json(raw)
      begin
        JSON.parse(raw)
      rescue Exception
        {}
      end
    end

    def working?
      event_created_within?(interpolated['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def validate_options
      unless options['secret'].present?
        errors.add(:base, "Must specify a secret for 'Authenticating' requests")
      end

      if options['code'].present? && options['code'].to_s !~ /\A\s*(\d+|\{.*)\s*\z/
        errors.add(:base, "Must specify a code for request responses")
      end

      if options['code'].to_s.in?(['301', '302']) && !options['response'].present?
        errors.add(:base, "Must specify a url for request redirect")
      end
    end
  end
end
