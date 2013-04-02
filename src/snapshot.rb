class Snapshot
  WORKING_DIR = '/home/pi/stopa_monitor'
  CAPTURE_DEVICES = {
    '0c45:7401' => ThermometerTEMPer1,
    '041e:4095' => CameraCreativeLiveHD
  }
  
  TRANSFER_DEVICES = {
    '12d1:141b' => ModemHuaweiE1752
  }
  
  def initialize
    @timestamp = Time.now.strftime "%Y%m%d_%H%M%S"
    @snapshot_dir = File.join WORKING_DIR, @timestamp
    Dir.mkdir @snapshot_dir
    
    logfile_path = File.join @snapshot_dir, 'stopa.log'
    @logger = Logger.new logfile_path
    @logger.datetime_format = '%Y-%m-%d %H:%M:%S'

    @logger.info 'Stopa Monitor 2.0: starting data capture session'
  end
  
  def detect_devices
    @capture_devices = []
    @transfer_devices = []
    lsusb = `lsusb`
    device_ids = lsusb.split("\n").collect{|l| l.split(' ')[5]}
    device_ids.each do |device_id|
      if CAPTURE_DEVICES[device_id]
        device_klass = CAPTURE_DEVICES[device_id]
        @capture_devices << device_klass
      end
      
      if TRANSFER_DEVICES[device_id]
        device_klass = TRANSFER_DEVICES[device_id]
        @transfer_devices << device_klass
      end 
    end
    @logger.info "detected following capture devices: #{@capture_devices.join(', ')}"
    @logger.info "detected following transfer devices: #{@transfer_devices.join(', ')}"
  end
  
  def capture_data
    @capture_devices.each do |device_klass|
      begin
        @logger.info "initializing device: #{device_klass}"
        device = device_klass.new @logger, @snapshot_dir
        @logger.info "device is about to capture data"
        device.capture
        @logger.info "done"
      rescue => e
        @logger.error "#{e} #{e.class}"
      end
    end
  end
  
  def in_trasmission_window &block
    if @transfer_devices.size == 0
      @logger.warn "no trasfer devices found"
    else
      
      device_klass = @transfer_devices.first
      @logger.info "using #{device_klass}"
      device = device_klass.new @logger
      begin
        device.connect
        if device.connected?
          sleep 10 # make sure the connection is really established
          block.call
        end
      rescue => e
        @logger.error "#{e} #{e.class}"
      ensure
        device.disconnect
      end
    end
  end
  
  def upload upload_config
    
    host = upload_config::HOST
    login = upload_config::LOGIN
    password = upload_config::PASSWORD
    remote_working_dir = upload_config::REMOTE_WORKING_DIR
    
    @logger.info "About to upload data to '#{host}' as user '#{login}'"

    begin    
      ftp = Net::FTP.new host
      ftp.login login, password
    
      @logger.info 'connection established'
    

      remote_snapshot_dir = File.join remote_working_dir, @timestamp
      ftp.mkdir remote_snapshot_dir
      @logger.debug "created remote upload dir #{remote_snapshot_dir}"
      files_to_transfer = Dir.glob File.join(@snapshot_dir, '*[!log]') # TODO: upload the log file as the last file and measure upload speed/time
      
      @logger.info "About to upload #{files_to_transfer.size} files"
      
      files_to_transfer.each do |local_file_path|
        filename = File.basename local_file_path
        remote_file_path = File.join remote_snapshot_dir, filename
        t1 = Time.now
        ftp.putbinaryfile local_file_path, remote_file_path
        t2 = Time.now
        time_diff = (t2 - t1).round 2
        @logger.debug "uploaded file: #{filename}. size:#{File.size(local_file_path)} bytes. upload time:#{time_diff} seconds"
      end
    rescue => e
      @logger.info "ftp upload problem: #{e.class} #{e}"
    ensure
      begin
        ftp.close
      rescue
      end
    end
    
    @logger.info 'upload finished'
  end
  
  def close
    @logger.info "closing snapshot"
    @logger.close
  end
end