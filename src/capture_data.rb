require 'logger'
require 'timeout'

# crontab: run every 30 minutes: */30 * * * * ruby /home/pi/stopa_monitor/capture_data.rb

WORKING_DIR = '/home/pi/stopa_monitor/'

logfile_path = File.join WORKING_DIR, 'stopa.log'
logger = Logger.new logfile_path
logger.datetime_format = '%Y-%m-%d %H:%M:%S'

logger.info 'Stopa Monitor 2.0: starting data capture session'
##################

begin
  
  logger.info 'about to measure temperature'

  temperature_for_photo_filename = 'unknown'
  begin
    Timeout::timeout(5) do
      pcsensor_output = `sudo pcsensor -c 2>&1`
      logger.debug pcsensor_output # "2013/03/28 20:20:10 Temperature 23.56C\n"
      temperature = pcsensor_output.split(' ').last
      if temperature.include?('C')
        logger.info "parsed temperature: #{temperature}"
        temperature_for_photo_filename = temperature.sub! '.', '_'
        if temperature_for_photo_filename.include?('-')
          temperature_for_photo_filename.sub! '-', ''
          temperature_for_photo_filename = "minus#{temperature_for_photo_filename}"
        else
          temperature_for_photo_filename = "plus#{temperature_for_photo_filename}"
        end
      else
        logger.error 'failed to parse temperature'
      end
    end
  rescue Timeout::Error
    logger.error '5 second timeout expired while measuring temperature'
  end

  ###################

  logger.info 'about to take a photo'
  timestamp = Time.now.strftime "%Y%m%d_%H%M%S"
  photo_filename = "#{timestamp}.t.#{temperature_for_photo_filename}.jpg"
  photo_fullpath = File.join WORKING_DIR, photo_filename

  begin
    Timeout::timeout(15) do
      logger.debug `fswebcam --no-banner -d /dev/video0 -i 0 -r 1280x720 --jpeg 93 -D 1 #{photo_fullpath} 2>&1`
    end
  rescue Timeout::Error
    logger.error '15 second timeout expired while taking photo'
  end

  if File.exists?(photo_fullpath)
    size = File.size photo_fullpath
    logger.info "photo successfully taken: #{photo_fullpath}. size: #{size} bytes"
  else
    logger.error 'photo not created'
  end
  
rescue => e
  logger.error "something bad happened: #{e} #{e.class}"
  logger.error e.backtrace[0..4].to_s
end
##################
logger.info 'Stopa Monitor 2.0: finished data capture session'

exit 0