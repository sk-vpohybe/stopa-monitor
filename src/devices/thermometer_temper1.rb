class ThermometerTEMPer1 # 'TEMPer1V1.2'
  TIMEOUT = 15 #seconds
  OUTPUT_FILE = 'temperature_temper1.txt'

  def initialize logger, snapshot_dir
    @logger = logger
    @temperature = 'unknown'
              
    @output_file = File.join snapshot_dir, OUTPUT_FILE
  end

  def capture
    begin
      Timeout::timeout(TIMEOUT) do
        # there is some issue with pcsensors binary - eah 13th measurement fails with USB interrupt read: Resource temporarily unavailable
        3.times do |i|
          raw_output = `sudo pcsensor -c 2>&1`
          @logger.debug "Measurement No #{i+1}: #{raw_output}" # "2013/03/28 20:20:10 Temperature 23.56C\n"
          t = raw_output.split(' ').last
          if t.include?('C')
            @logger.info "parsed temperature: #{t}"
            @temperature = t
            break
          else
            @logger.error "failed to parse temperature"
            sleep 1
          end
        end
      end
    rescue Timeout::Error
      @logger.error 'timeout expired during measurement'
    end
    
    @logger.info "writing capture temperature to #{@output_file}"
    File.open(@output_file, 'w'){|f| f.write @temperature}
  end
end