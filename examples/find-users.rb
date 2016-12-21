#!/usr/bin/env ruby

require 'dotenv'
Dotenv.load ".env.development", '.env'

token = ENV['PAGERDUTY_TOKEN'] || raise("Missing ENV['PAGERDUTY_TOKEN'], add to .env.development")

require 'pager_duty/connection'
$pagerduty = PagerDuty::Connection.new(token)

# https://v2.developer.pagerduty.com/v2/page/api-reference#!/Users/get_users
response = $pagerduty.get('users')
response['users'].each do |user|
  puts "#{user['name']}: #{user['email']}"
end
