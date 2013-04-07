class CameraCanyonCNR113  #  Canyon CNR-FWC113
  include DaylightDetector
  
  TIMEOUT = 15 #seconds
  OUTPUT_FILE = 'photo_canyon_cnr_113.jpg'

  def initialize logger, snapshot_dir
    @logger = logger
              
    @output_file = File.join snapshot_dir, OUTPUT_FILE
  end
  
  def capture
    if daylight?(StopaMonitorConfig::LATITUDE, StopaMonitorConfig::LONGITUDE)
      begin
        Timeout::timeout(15) do
          @logger.debug `fswebcam --no-banner -d /dev/video0 -i 0 -r 640x480 --jpeg 80 -D 1 #{@output_file} 2>&1`
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