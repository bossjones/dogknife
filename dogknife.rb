#!/usr/bin/env ruby
require 'rubygems'
require 'chef/config'
require 'chef/knife'
require 'chef/application/knife'
require 'dogapi'

# Save Chef::Knife.run to wrap it
# There may be a much more natural way to monkey-patch methods in ruby
$real_run = Chef::Knife.method(:run)

class Chef
  class Knife
    def self.run(args, options={})
      start = Time.now.to_i
      $real_run.call(args, options)
      duration = Time.now.to_i - start
      # skip help
      unless args.include?("help") && args.include?("--help")

        # Look up some properties
        if Chef::Config.has_key?("datadog_user")
          who = Chef::Config.datadog_user
        else
          who = %x[whoami].strip
        end
        if Chef::Config.has_key?("datadog_api_key")
          dog = Dogapi::Client.new(Chef::Config.datadog_api_key)
        else
          dog = Dogapi::Client.new(ENV['DATADOG_KEY'])
        end

        # Emit event to Datadog
        dog.emit_event(Dogapi::Event.new("#{args.join(' ')}",
                                         :msg_title       => "#{who} ran: knife #{args.join(' ')} in #{duration} seconds",
                                         :aggregation_key => "#{who}-knife",
                                         :alert_type      => "info",
                                         :source_type_name => "chef",
                                         :tags            => ["knife"]
                                         ))
      end
    end
  end
end

Chef::Application::Knife.new.run
