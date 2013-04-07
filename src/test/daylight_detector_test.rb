require "test/unit"
require '../lib/daylight_detector.rb'
 
class DaylightDetectorTest < Test::Unit::TestCase
  include DaylightDetector
 
  def setup
    @lat, @lon = "48.1485", "17.1067"
  end
  
  def test_19pm_during_summer_is_daylight_in_slovakia
    time = Time.new 2013, 6, 30, 19, 0, 0
    assert daylight?(@lat, @lon, time)
  end
  
  def test_19pm_during_winter_is_not_daylight_in_slovakia
    time = Time.new 2013, 12, 30, 19, 0, 0
    assert !daylight?(@lat, @lon, time)
  end
 
  def test_5am_during_winter_is_not_daylight_in_slovakia
    time = Time.new 2013, 12, 30, 5, 0, 0
    assert !daylight?(@lat, @lon, time)
  end
  
  def test_5am_during_summer_is_daylight_in_slovakia
    time = Time.new 2013, 6, 30, 5, 0, 0
    assert daylight?(@lat, @lon, time)
  end
end