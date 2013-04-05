require 'logger'
require 'timeout'
require 'net/ftp'

current_path = File.absolute_path(File.dirname(__FILE__))

devices = Dir.glob File.join(current_path, 'devices/*.rb')
devices.each {|d| require d}
require File.join(current_path, 'snapshot.rb')
require File.join(current_path, 'upload_config.rb')
require File.join(current_path, 'network_status.rb')

s = Snapshot.new
s.detect_devices
s.capture_data

s.in_trasmission_window do
  s.upload
end

s.close
exit 0