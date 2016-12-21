#!/usr/bin/env ruby

require 'dotenv'
Dotenv.load ".env.development", '.env'

token = ENV['PAGERDUTY_TOKEN'] || raise("Missing ENV['PAGERDUTY_TOKEN'], add to .env.development")

require 'pager_duty/connection'
$pagerduty = PagerDuty::Connection.new(token)

schedule_id = ENV['PAGERDUTY_SCHEDULE_ID'] || raise("Missing ENV['PAGERDUTY_SCHEDULE_ID'], add to .env.development")

# pull down schedule entires for XXX schedule in the last day (ie who has been on call, and when
time_since = 1.day.ago
time_until = Time.now

# https://v2.developer.pagerduty.com/v2/page/api-reference#!/On-Calls/get_oncalls
response = $pagerduty.get("oncalls", query_params: { since: time_since, until: time_until, schedule_ids: [schedule_id] })

entries = response['oncalls']

entries.each do |entry|
  puts "#{entry['start']} - #{entry['end']}: #{entry['user']['summary']}"

  # find incidents during that shift
  # https://v2.developer.pagerduty.com/v2/page/api-reference#!/Incidents/get_incidents
  response = $pagerduty.get('incidents', query_params: { since: entry['start'], until: entry['end'], user_ids: [entry['user']['id']] })

  response['incidents'].each do |incident|
    puts "\t#{incident.id}"

    # find log entries (acknowledged, notifications, etc) for incident:
    # https://v2.developer.pagerduty.com/v2/page/api-reference#!/Incidents/get_incidents_id_log_entries
    response = $pagerduty.get("incidents/#{incident.id}/log_entries")

    # select just the notes
    notes = response['log_entries'].select do |log_entry|
      log_entry['channel'] && log_entry['channel']['type'] == 'note'
    end

    # and print them out:
    notes.each do |log_entry|
      puts "\t\t#{log_entry['channel']['summary']}"
    end
  end
end
