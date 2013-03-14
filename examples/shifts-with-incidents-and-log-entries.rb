#!/usr/bin/env ruby

require 'dotenv'
Dotenv.load ".env.development", '.env'

account = ENV['PAGERDUTY_ACCOUNT'] || raise("Missing ENV['PAGERDUTY_ACCOUNT'], add to .env.development")
token = ENV['PAGERDUTY_TOKEN'] || raise("Missing ENV['PAGERDUTY_TOKEN'], add to .env.development")

require 'pager_duty/connection'
$pagerduty = PagerDuty::Connection.new(account, token)

schedule_id = ENV['PAGERDUTY_SCHEDULE_ID'] || raise("Missing ENV['PAGERDUTY_SCHEDULE_ID'], add to .env.development")

# pull down schedule entires for XXX schedule in the last day (ie who has been on call, and when
time_since = 1.day.ago
time_until = Time.now

# http://developer.pagerduty.com/documentation/rest/schedules/entries
response = $pagerduty.get("schedules/#{schedule_id}/entries", 'since' => time_since, 'until' => time_until, :overflow => true)

entries = response['entries'] # note, probably a bug, but response.entries doesn't do what you think it does

entries.each do |entry|
  puts "#{entry.start} - #{entry.end}: #{entry.user.name}"

  # find incidents during that shift
  # http://developer.pagerduty.com/documentation/rest/incidents/list
  response = $pagerduty.get('incidents', :since => entry['start'], :until => entry['end'])

  response.incidents.each do |incident|
    puts "\t#{incident.id}"

    # find log entries (acknowledged, notifications, etc) for incident:
    # http://developer.pagerduty.com/documentation/rest/log_entries/incident_log_entries
    response = $pagerduty.get("incidents/#{incident.id}/log_entries")

    # select just the notes
    notes = response.log_entries.select do |log_entry|
      log_entry.channel && log_entry.channel.type == 'note'
    end

    # and print them out:
    notes.each do |log_entry|
      puts "\t\t#{log_entry.channel.summary}"
    end
  end
end
