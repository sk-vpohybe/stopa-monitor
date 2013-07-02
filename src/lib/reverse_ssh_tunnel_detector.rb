class ReverseSSHTunnelDetector
  def initialize logger, ftp_connection
    @logger = logger
    @ftp = ftp_connection
    @reverse_ssh_tunnel_port = nil
  end
  
  def detect_port
    @logger.debug "checking if server asks us to establish reverse ssh tunnel"
    expected_file = File.join StopaMonitorConfig::REMOTE_WORKING_DIR, 'REVERSE_SSH_TUNNEL_PORT_*'
    first_line = @ftp.list(expected_file).first
    #  "-rw-rw-r--   1 stopa_monitor3 stopa_monitor3        0 Jun  4 19:21 /home/stopa_monitor3/snapshots/REVERSE_SSH_TUNNEL_PORT_4321"
    if first_line
      port_no = first_line.match(/REVERSE_SSH_TUNNEL_PORT_(\d+)/)[1]
      @reverse_ssh_tunnel_port = port_no.to_i
      @logger.info "server asked us to establish reverse ssh tunnel on port #{@reverse_ssh_tunnel_port.inspect}"
    else
      @logger.debug "server did not want us to establish reverse ssh tunnel"
    end
    
    return @reverse_ssh_tunnel_port
  end
end