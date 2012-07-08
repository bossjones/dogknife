#!/usr/bin/env ruby
require 'rubygems'
require 'chef/config'
require 'chef/knife'
require 'chef/log'
require 'chef/application/knife'
require 'dogapi'

# Save Chef::Knife.run to wrap it
# There may be a much more natural way to monkey-patch methods in ruby
$real_run = Chef::Knife.method(:run)

class Chef
  class Knife
    def self.run(args, options={})
      # Capture logging
      lrd, lwr = IO.pipe
      dd_logger = Logger.new(lwr)
      Chef::Log.loggers << dd_logger

      # Measure duration
      start = Time.now.to_i
      # Call run
      $real_run.call(args, options)

      duration = Time.now.to_i - start

      # Don't capture help messages skip help
      unless args.include?("help") && args.include?("--help")

        # Look up some properties
        who = %x[whoami].strip
        if Chef::Config.has_key?("datadog_user")
          who = Chef::Config.datadog_user
        end

        dog = nil
        if Chef::Config.has_key?("datadog_api_key")
          dog = Dogapi::Client.new(Chef::Config.datadog_api_key)
        elsif ENV.has_key?("DATADOG_KEY")
          dog = Dogapi::Client.new(ENV['DATADOG_KEY'])
        else
          self.msg("Missing datadog_api_key in knife configuration")
        end
        
        # Emit event to Datadog
        unless dog.nil?
          begin
            lwr.close_write
            logged = lrd.read
            body = "Nothing logged"
            body = "Knife logged\n@@@#{logged}@@@" if logged.length > 0
            dog.emit_event(Dogapi::Event.new(body,
                                             :msg_title       => "#{who} ran: knife #{args.join(' ')} in #{duration} second(s)",
                                             :event_type      => "config_management.command",
                                             :aggregation_key => "#{who}-knife",
                                             :alert_type      => "info",
                                             :source_type_name => "chef",
                                             :tags            => ["knife"]
                                             ))
          rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
            ui.error("Could not send data to Datadog")
          end
        end
      end
    end
  end
end

Chef::Application::Knife.new.run
