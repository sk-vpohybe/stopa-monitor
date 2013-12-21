class ModemHuaweiE220
 
# /etc/wvdial.conf
# [Dialer Defaults]
# Init1 = AT
# ;Init2 = AT+CPIN="0000"
# Init4 = ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0
# Init3 = AT+CGDCONT=1,"IP","internet"
# Phone = *99***1#
# ISDN = 1
# Username = internet
# Password = internet
# Modem = /dev/ttyUSB0
# Baud = 460800
# Stupid Mode = on
  
  NETWORK_INTERFACE = 'ppp0'
  def initialize logger
    @logger = logger
  end
  
  def connect
    @logger.info "trying to connect Huawei E169/E620/E800 HSDPA Modem"
    Thread.new {`sudo wvdial >>#{@logger.logfile_path} 2>&1 &`}
    10.times do
      sleep 3
      return if connected?
    end
    
    disconnect
  end
  
  def connected?
    ifconfig_status = `/sbin/ifconfig #{NETWORK_INTERFACE} 2>&1`
    @logger.debug ifconfig_status
    if ifconfig_status.include?('Device not found')
      @logger.info "network interface #{NETWORK_INTERFACE} not found"
      return false 
    else
      if ifconfig_status.include?('RUNNING')
        @logger.info "network interface #{NETWORK_INTERFACE} is connected"
        return true
      else
        @logger.info "network interface #{NETWORK_INTERFACE} found, but is not connected"
        return false 
      end
    end
  end
  
  def disconnect
    @logger.info "disconnecting network interface #{NETWORK_INTERFACE}"
    @logger.debug `sudo pkill wvdial 2>&1`
  end
end