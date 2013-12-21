current_path = File.absolute_path(File.dirname(__FILE__))
devices = Dir.glob File.join(current_path, '../devices/*.rb')
devices.each {|d| require d}

class DeviceDetector
  USB_CAPTURE_DEVICES = { 
    '0c45:7401' => ThermometerTEMPer1,
    '041e:4095' => CameraCreativeLiveHD,
    '0c45:6340' => CameraCanyonCNR113,
    '046d:0825' => CameraLogitechC270,
    '093a:2700' => CameraPixart,
    '12d1:141b' => SimCardSMS,
    '12d1:1001' => SimCardSMS
  }
  
  USB_TRANSFER_DEVICES = { 
    '12d1:141b' => ModemHuaweiE1752,
    '12d1:1001' => ModemHuaweiE169,
    '0471:1210' => ModemVodafoneMD950,
    '1dbc:0005' => ModemVodafoneMD950,
    '12d1:1003' => ModemHuaweiE220
  }
  
  OTHER_CAPTURE_DEVICES = [ThermometerHygrometerDHT11]
  
  def initialize logger
    @logger = logger
  end
  
  def detect_devices
    capture_devices = []
    transfer_devices = []
    lsusb = `lsusb`
    device_ids = lsusb.split("\n").collect{|l| l.split(' ')[5]}
    device_ids.each do |device_id|
      if USB_CAPTURE_DEVICES[device_id]
        device_klass = USB_CAPTURE_DEVICES[device_id]
        capture_devices << device_klass
      end
      
      if USB_TRANSFER_DEVICES[device_id]
        device_klass = USB_TRANSFER_DEVICES[device_id]
        transfer_devices << device_klass
      end 
    end
    
    # there is no way how to detect GPIO/other devices, way have to trust StopaMonitorConfig::ATTACHED_CAPTURE_DEVICES
    StopaMonitorConfig::ATTACHED_CAPTURE_DEVICES.each do |device_klass|
      if OTHER_CAPTURE_DEVICES.include? device_klass
        capture_devices << device_klass
      end
    end
    
    @logger.info "detected following capture devices: #{capture_devices.join(', ')}"
    @logger.info "detected following transfer devices: #{transfer_devices.join(', ')}"
    
    return [capture_devices, transfer_devices]
  end
end