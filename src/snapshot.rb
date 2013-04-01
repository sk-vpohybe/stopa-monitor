class Snapshot
  WORKING_DIR = '/home/pi/stopa_monitor'
  CAPTURE_DEVICES = {
    '0c45:7401' => ThermometerTEMPer1,
    '041e:4095' => CameraCreativeLiveHD
  }
  
  def initialize
    timestamp = Time.now.strftime "%Y%m%d_%H%M%S"
    @snapshot_dir = File.join WORKING_DIR, timestamp
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
      device = device_klass.new @logger, @snapshot_dir
      device.capture
    end
  end
end