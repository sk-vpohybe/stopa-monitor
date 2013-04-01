class Snapshot
  WORKING_DIR = '/home/pi/stopa_monitor'
  CAPTURE_DEVICES = {
    '0c45:7401' => ThermometerTEMPer1,
    '041e:4095' => CameraCreativeLiveHD
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
    lsusb = `lsusb`
    device_ids = lsusb.split("\n").collect{|l| l.split(' ')[5]}
    device_ids.each do |device_id|
      if CAPTURE_DEVICES[device_id]
        device_klass = CAPTURE_DEVICES[device_id]
        @capture_devices << device_klass
      end
    end
    
    @logger.info "detected following capturable devices: #{@capture_devices.join(', ')}"
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
  
  def upload upload_config
    
    host = upload_config::HOST
    login = upload_config::LOGIN
    password = upload_config::PASSWORD
    remote_working_dir = upload_config::REMOTE_WORKING_DIR
    
    @logger.info "About to upload data to '#{host}' as user '#{login}'"
    
    ftp = Net::FTP.new host
    ftp.login login, password
    
    @logger.info 'connection established'
    
    begin
      remote_snapshot_dir = File.join remote_working_dir, @timestamp
      ftp.mkdir remote_snapshot_dir
      @logger.debug "created remote upload dir #{remote_snapshot_dir}"
      files_to_transfer = Dir.glob File.join(@snapshot_dir, '*') # TODO: upload the log file as the last file and measure upload speed/time
      
      @logger.info "About to upload #{files_to_transfer.size} files"
      
      files_to_transfer.each do |local_file_path|
        filename = File.basename local_file_path
        remote_file_path = File.join remote_snapshot_dir, filename
        ftp.putbinaryfile local_file_path, remote_file_path
      end
    ensure
      ftp.close
    end
    
    @logger.info 'upload finished'
  end
  
  def close
    @logger.close
  end
end