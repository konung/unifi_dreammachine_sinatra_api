require 'sinatra'
require_relative 'unifi_api'

set :bind, '0.0.0.0'

before do
  @unifi_api = UniFiAPI.new(ENV['USERNAME'], ENV['PASSWORD'])
rescue UniFiAPI::LoginError, UniFiAPI::CSRFTokenError => e
  halt 500, "Error: #{e.message}"
end

get '/toggle' do
  api_token = params['api_token']
  rule_id = params['rule_id']

  if api_token == ENV['API_TOKEN']
    @unifi_api.toggle_traffic_rule(ENV['SITE_NAME'], rule_id)
    'Toggle request has been processed.'
  else
    'Unauthorized.'
  end
end

get '/status' do
  api_token = params['api_token']

  if api_token == ENV['API_TOKEN']
    @unifi_api.show_traffic_rules_status(ENV['SITE_NAME'])
    'Status request has been processed.'
  else
    'Unauthorized.'
  end
end
