require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::RawWebhookAgent do
  before(:each) do
    @valid_options = Agents::RawWebhookAgent.new.default_options
    @checker = Agents::RawWebhookAgent.new(:name => "RawWebhookAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
