class CameraCreativeLiveHD
  TIMEOUT = 15 #seconds
  OUTPUT_FILE = 'photo.jpg'

  def initialize logger, snapshot_dir
    @logger = logger
    @temperature = 'unknown'
              
    @output_file = File.join snapshot_dir, OUTPUT_FILE
    @logger.info 'initialized cam Creative Live! Cam Sync HD'
  end
  
  def capture
    @logger.info 'about to take a photo'
    begin
      begin
        Timeout::timeout(15) do
          @logger.debug `fswebcam --no-banner -d /dev/video0 -i 0 -r 1280x720 --jpeg 93 -D 1 #{@output_file} 2>&1`
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
  
    rescue => e
      @logger.error "something bad happened: #{e} #{e.class}"
      @logger.error e.backtrace[0..4].to_s
    end
  end
end