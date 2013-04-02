require 'logger'
require 'timeout'
require 'net/ftp'

devices = Dir.glob './devices/*.rb'
devices.each {|d| require d}
require './snapshot.rb'
require './upload_config.rb'

s = Snapshot.new
s.detect_devices
s.capture_data

s.in_trasmission_window do
  s.upload UploadConfig
end

s.close
exit 0