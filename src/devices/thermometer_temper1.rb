class ThermometerTEMPer1 # 'TEMPer1V1.2'
  TIMEOUT = 5 #seconds
  OUTPUT_FILE = 'temperature_temper1.txt'

  def initialize logger, snapshot_dir
    @logger = logger
    @temperature = 'unknown'
              
    @output_file = File.join snapshot_dir, OUTPUT_FILE
    @logger.info 'initialized thermometer Microdia TEMPer1V1.2 device'
  end

  def capture
    @logger.info 'Capturing temperature'
    begin
      begin
        Timeout::timeout(TIMEOUT) do
          raw_output = `sudo pcsensor -c 2>&1`
          @logger.debug raw_output # "2013/03/28 20:20:10 Temperature 23.56C\n"
          t = raw_output.split(' ').last
          if t.include?('C')
            @logger.info "parsed temperature: #{t}"
            @temperature = t
          else
            @logger.error "failed to parse temperature from raw output: #{raw_output}"
          end
        end
      rescue Timeout::Error
        @logger.error 'timeout expired during measurement'
      end
              
    rescue => e
      @logger.error "#{e} #{e.class}"
      @logger.error e.backtrace[0..4].to_s
    end
    
    @logger.info "writing capture temperature to #{@output_file}"
    File.open(@output_file, 'w'){|f| f.write @temperature}
  end
end