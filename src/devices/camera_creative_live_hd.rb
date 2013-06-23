class CameraCreativeLiveHD
  include DaylightDetector
  
  TIMEOUT = 30 #seconds
  OUTPUT_FILE = 'photo_creative_live_hd.jpg'

  def initialize logger, snapshot_dir
    @logger = logger
              
    @output_file = File.join snapshot_dir, OUTPUT_FILE
  end
  
  def capture
    if daylight?(StopaMonitorConfig::LATITUDE, StopaMonitorConfig::LONGITUDE)
      begin
        Timeout::timeout(TIMEOUT) do
          # we intentionally take three photos to allow the camera to autoset brightness/color
          cmd = 'fswebcam --no-banner -d /dev/video0 -i 0 -r 1280x720 --jpeg 80 -D 1 --set sharpness=1'
          @logger.debug `#{cmd} /dev/null 2>&1`
          sleep 2
          @logger.debug `#{cmd} /dev/null 2>&1`
          sleep 2
          @logger.debug `#{cmd} #{@output_file} 2>&1`
        end
      rescue Timeout::Error
        @logger.error '15 second timeout expired while taking photo'
      end

      if File.exists?(@output_file)
        size = File.size @output_file
        @logger.info "photo successfully taken: #{@output_file}. size: #{size} bytes"
      else
        @logger.error 'photo not created'
      end
    else
      @logger.info "not taking photo, no daylight"
    end
  end
end