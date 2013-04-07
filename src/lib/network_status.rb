class NetworkStatus
  def initialize logger, ping_host = '8.8.8.8'
    @logger = logger
    @ping_host = ping_host
  end
  
  def connected?    
    interface = running_interface
    if interface
      @logger.info "NetworkStatus: connected to network via #{interface}"
      if ping_ok?
        @logger.info "NetworkStatus: ping test successful"
        return true
      else
        @logger.info "NetworkStatus: ping test unsuccessful"
        return false
      end
    else
      @logger.info "NetworkStatus: not connected to network"
      return false
    end
  end
  
  private
  def running_interface
    interfaces = `/sbin/ifconfig -s 2>&1`.split("\n")[1..-1].collect{|line| line.split(' ').first}
    (interfaces - ['lo']).each do |interface|
      ifconfig_status = `/sbin/ifconfig #{interface} 2>&1`
      if ifconfig_status.include?('RUNNING')
        return interface
      end
    end
    return nil
  end
  
  def ping_ok?
    @logger.debug "NetworkStatus: pinging #{@ping_host}"
    p = `ping #{@ping_host} -c 1 -W 10 2>&1`
    @logger.debug p
    p.include?('1 packets transmitted, 1 received')
  end
end