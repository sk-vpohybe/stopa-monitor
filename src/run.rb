puts "Starting Stopa Monitor"

# source: http://rosettacode.org/wiki/Determine_if_only_one_instance_is_running#Ruby
unless File.new(__FILE__).flock(File::LOCK_EX | File::LOCK_NB)
  puts "There is already an instance running, I quit"
  exit 1
end

require 'rubygems'
require 'bundler/setup'
require 'timeout'

current_path = File.absolute_path(File.dirname(__FILE__))

libs = Dir.glob File.join(current_path, 'lib/*.rb')
libs.each {|l| require l}

devices = Dir.glob File.join(current_path, 'devices/*.rb')
devices.each {|d| require d}

require  File.join current_path, 'snapshot.rb'
require  File.join current_path, 'stopa_monitor_config.rb'

s = Snapshot.new
s.detect_devices
s.run_health_check
s.capture_data

s.in_trasmission_window do
  s.upload
  s.establish_reverse_ssh_tunnel_if_required_by_server
end
s.cleanup
s.close_and_reboot_if_necessary

exit 0