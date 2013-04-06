require 'timeout'
require 'net/ftp'

current_path = File.absolute_path(File.dirname(__FILE__))

devices = Dir.glob File.join(current_path, 'devices/*.rb')
devices.each {|d| require d}
['snapshot.rb', 'upload_config.rb', 'network_status.rb', 'open_logger.rb'].each do |rb|
  require File.join(current_path, rb)
end

s = Snapshot.new
s.detect_devices
s.capture_data

s.in_trasmission_window do
  s.upload
end

s.close
exit 0