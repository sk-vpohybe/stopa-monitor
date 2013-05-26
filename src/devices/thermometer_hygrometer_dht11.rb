# very cheap GPIO device - we use it to monitor temp/humidity inside the ABS case with RPi

class ThermometerHygrometerDHT11
  TIMEOUT = 10 # seconds
  OUTPUT_FILE = 'humidity_temperature_dht11.txt'

  def initialize logger, snapshot_dir
    @logger = logger
    @temperature = 'unknown'
    @humidity = 'unknown'
              
    @output_file = File.join snapshot_dir, OUTPUT_FILE
  end

  def capture
    begin
      Timeout::timeout(TIMEOUT) do
        5.times do
          raw_output = `sudo dht11_v2 2>&1`
          if $?.exitstatus == 0
            raw_output_h_t = raw_output.split "\n"
            @humidity = raw_output_h_t[0].gsub('Humidity:', '').to_f
            @temperature = raw_output_h_t[1].gsub('Temperature:', '').to_f
            @logger.debug "ThermometerHygrometerDHT11: relative humidity: #{@humidity}%, temperature: #{@temperature}C"
            break
          end
        end
        
        if @humidity == 'unknown'
          @logger.error 'ThermometerHygrometerDHT11: measurement not successful'
        end
      end
    rescue Timeout::Error
      @logger.error 'ThermometerHygrometerDHT11: timeout expired during measurement'
    end

    if @humidity != 'unknown'
      @logger.info "writing capture temperature to #{@output_file}"
      File.open(@output_file, 'w'){|f| f.write "Humidity:#{@humidity}%\nTemperature:#{@temperature}C"}
    end
  end
end