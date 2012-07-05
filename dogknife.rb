#!/usr/bin/env ruby
require 'rubygems'
require 'chef/config'
require 'chef/application/knife'
require 'dogapi'

# First approach, wrap the call
start = Time.now.to_i
args = ARGV

begin
  Chef::Application::Knife.new.run
rescue SystemExit
  duration = Time.now.to_i - start
  # cheap identification, ideally, pull this from .chef/knife.rb, defaults to whoami
  who = %x[whoami].strip
  # skip help
  unless ARGV.include?("help") && ARGV.include?("--help")
    # will be replaced by a lookup in .chef/knife.rb
    if Chef::Config.has_key?("datadog_api_key")
      dog = Dogapi::Client.new(Chef::Config.datadog_api_key)
    else
      dog = Dogapi::Client.new(ENV['DATADOG_KEY'])
    end
    dog.emit_event(Dogapi::Event.new("#{ARGV.join(' ')}",
                                     :msg_title       => "#{who} ran: knife #{ARGV.join(' ')} in #{duration} seconds",
                                     :aggregation_key => "#{who}-knife",
                                     :alert_type      => "info",
                                     :source_type_name => "chef",
                                     :tags            => ["knife"]
                                     ))
  end
end
exit 0

