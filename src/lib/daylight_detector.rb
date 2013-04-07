require 'solareventcalculator' # RubySunrise gem

module DaylightDetector
  def daylight? lat, lon, now = Time.now
    date = Date.parse now.to_s
    calc = SolarEventCalculator.new date, BigDecimal.new(lat), BigDecimal.new(lon)
    after_sunrise = calc.compute_utc_civil_sunrise < now.to_datetime
    before_sunset = now.to_datetime < calc.compute_utc_civil_sunset
    
    return (after_sunrise && before_sunset)
  end
end