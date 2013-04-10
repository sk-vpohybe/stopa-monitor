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
end
s.close
exit 0