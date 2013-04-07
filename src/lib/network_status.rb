class NetworkStatus
  def initialize logger, ping_host = '8.8.8.8'
    @logger = logger
    @ping_host = ping_host
  end
  
  def connected?
    ifconfig_status = `/sbin/ifconfig 2>&1`
    @logger.debug ifconfig_status
    
    if ifconfig_status.include?('RUNNING')
      @logger.info "NetworkStatus: connected to network"
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
  def ping_ok?
    @logger.debug "NetworkStatus: pinging #{@ping_host}"
    p = `ping #{@ping_host} -c 1 -W 10 2>&1`
    @logger.debug p
    p.include?('1 packets transmitted, 1 received')
  end
end