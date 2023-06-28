# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'faraday-cookie_jar'
require 'json'
require 'logger'

USERNAME = ENV['USERNAME']
PASSWORD = ENV['PASSWORD']
SITE_NAME = ENV['SITE_NAME']
BASE_URL = ENV['BASE_URL']
BASE_LOGIN_URL = "#{BASE_URL}/api/auth/login".freeze
BASE_API_URL = "#{BASE_URL}/proxy/network/".freeze

class UniFiAPI
  class LoginError < StandardError; end
  class CSRFTokenError < StandardError; end

  def initialize(username, password)
    @logger = Logger.new($stdout)
    @logger.info('Initializing UniFiAPI')

    # Initialize Faraday connection
    @conn = Faraday.new(BASE_URL, ssl: { verify: false }) do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/
      faraday.adapter Faraday.default_adapter
    end

    # Login
    @logger.info("Logging in with username: #{username}")
    response = @conn.post(BASE_LOGIN_URL, { username:, password: })
    if response.status == 200
      @logger.info('Login successful')
      @cookies = response.headers['set-cookie']

      # Obtain the CSRF token from the response headers
      csrf_token_header = response.headers['x-csrf-token']
      if csrf_token_header
        @csrf_token = csrf_token_header # Extract the token value from the header
        @logger.info("Setting CSRF token -  #{@csrf_token[0, 4]}...")
      else
        @logger.error('Failed to obtain CSRF token from the response headers')
        raise CSRFTokenError, 'Failed to obtain CSRF token from the response headers'
      end
    else
      @logger.error("Login failed with status code: #{response.status}")
      raise LoginError, "Login failed with status code: #{response.status}"
    end

    # List site information
    list_sites
  end

  def list_sites
    @logger.info('Listing site information')
    response = @conn.get("#{BASE_API_URL}api/s/default/self", nil, { 'Cookie' => @cookies })
    if response.status == 200
      @logger.info('Site information fetched successfully')
    #   puts JSON.pretty_generate(response.body)
    else
      @logger.error("Failed to fetch site information. Response: #{response.status} - #{response.body}")
    end
  end

  def list_traffic_rules(site_name = 'default')
    @logger.info("Fetching traffic rules for site: #{site_name}")
    response = @conn.get(BASE_API_URL + "v2/api/site/#{site_name}/trafficrules", nil, { 'Cookie' => @cookies })
    if response.status == 200
      @logger.info('Traffic rules fetched successfully')
      # puts JSON.pretty_generate(response.body)
    else
      @logger.error("Failed to fetch traffic rules. Response: #{response.status} - #{response.body}")
    end
  end

  def toggle_traffic_rule(site_name, rule_id)
    @logger.info("Toggling traffic rule #{rule_id} for site: #{site_name}")

    # Construct the URL for the traffic rules
    url = BASE_API_URL + "v2/api/site/#{site_name}/trafficrules"

    # Send a GET request to fetch all traffic rules
    response = @conn.get(url, nil, { 'Cookie' => @cookies })

    # Check the response
    if response.status == 200
      rules = response.body

      # Find the specific rule by ID
      rule = rules.find { |r| r['_id'] == rule_id }

      if rule.nil?
        @logger.error("Traffic rule #{rule_id} not found")
        return
      end

      # Update the rule with the new enable/disable value
      rule['enabled'] = !rule['enabled']
      enabled = rule['enabled']
      status = enabled ? 'enabled' : 'disabled'

      # Construct the URL for the specific traffic rule
      specific_url = url + "/#{rule_id}"

      # Send a PUT request to update the traffic rule
      put_response = @conn.put(specific_url, rule.to_json,
                               { 'Cookie' => @cookies, 'Content-Type' => 'application/json', 'X-CSRF-Token' => @csrf_token })

      # Check the response
      if put_response.status == 200
        message = "Traffic rule #{rule_id} (#{rule['description']}) successfully toggled. It's now: #{status} "
        @logger.info(message)
        message
      else
        @logger.error("Failed to toggle traffic rule. Response: #{put_response.status} - #{put_response.body}")
      end
    else
      @logger.error("Failed to fetch traffic rules. Response: #{response.status} - #{response.body}")
    end
  end

  # Function to show the current status of all traffic rules
  def show_traffic_rules_status(site_name)
    @logger.info("Fetching status of traffic rules for site: #{site_name}")

    # Construct the URL for the traffic rules
    url = BASE_API_URL + "v2/api/site/#{site_name}/trafficrules"

    # Send a GET request to fetch the traffic rules
    response = @conn.get(url, nil, { 'Cookie' => @cookies })

    # Check the response
    if response.status == 200
      response.body.map do |rule|
        rule_id = rule['_id']
        rule_desc = rule['description']
        enabled = rule['enabled']
        status = enabled ? 'enabled' : 'disabled'
        result = "Traffic rule #{rule_id} / #{rule_desc} is currently #{status}"
        @logger.info(result)
        "Traffic rule #{rule_id} / #{rule_desc} is currently #{status}"
      end
    else
      @logger.error("Failed to fetch traffic rules status. Response: #{response.status} - #{response.body}")
    end
  end
end
