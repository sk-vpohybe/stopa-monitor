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

#if s.connection_established?
  s.upload UploadConfig
#end

s.close