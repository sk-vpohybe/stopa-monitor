require 'logger'
require 'timeout'

devices = Dir.glob './devices/*.rb'
devices.each {|d| require d}
require './snapshot.rb'

s = Snapshot.new
s.detect_devices
s.capture_data