class ModemHuaweiE1752
  def initialize logger
    @logger = logger
  end
  
  def connect
    @logger.info "trying to connect Huawei E1752"
    Thread.new {`sudo wvdial orange &`}
    5.times do
      sleep 3
      return if connected?
    end
    
    disconnect
  end
  
  def connected?
    info = `ifconfig ppp0 2>&1`
    if info.include?('Device not found')
      @logger.info "not connected"
      return false 
    else
      #TODO: check if interface is RUNNING
      @logger.info "we are connected"
      return true
    end
  end
  
  def disconnect
    @logger.info "disconnecting"
    `sudo pkill wvdial`
  end
end