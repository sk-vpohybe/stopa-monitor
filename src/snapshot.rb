require 'net/ftp'
require 'net/ssh'

class Snapshot
  WORKING_DIR = '/home/pi/snapshots'
  
  def initialize
    @timestamp = Time.now.strftime "%Y%m%d_%H%M%S"
    @snapshot_dir = File.join WORKING_DIR, @timestamp
    @reverse_ssh_tunnel_port = nil
    
    Dir.mkdir @snapshot_dir
    
    logfile_path = File.join @snapshot_dir, 'stopa.log'
    puts "logfile path: #{logfile_path}"
    @logger = OpenLogger.new logfile_path
    @logger.datetime_format = '%Y-%m-%d %H:%M:%S'

    @logger.info 'Stopa Monitor 2.0: starting data capture session'
  end
  
  def detect_devices
    @capture_devices, @transfer_devices = DeviceDetector.new(@logger).detect_devices
  end
  
  def run_health_check
    h = HealthCheck.new @logger, @capture_devices, @transfer_devices
    h.run
    h.save_results_to_file File.join(@snapshot_dir, 'health_check.txt')
    @health_check_ok = h.ok
  end
  
  def capture_data
    @capture_devices.each do |device_klass|
      begin
        @logger.info "initializing device: #{device_klass}"
        device = device_klass.new @logger, @snapshot_dir
        @logger.info "device #{device_klass} is about to capture data"
        device.capture
        @logger.info "device #{device_klass} finished data capture"
      rescue => e
        @logger.error "#{e} #{e.class}"
      end
    end
  end
  
  def in_trasmission_window &block
    network_status = NetworkStatus.new @logger, StopaMonitorConfig::HOST
    
    if network_status.connected?
      @logger.info "wont use any tranfer device, connection is already established"
      block.call
    else
      
      if @transfer_devices.size == 0
        @logger.warn "no trasfer devices found"
      else
      
        device_klass = @transfer_devices.first
        @logger.info "using trasfer device #{device_klass}"
        device = device_klass.new @logger
        begin
          device.connect
          if device.connected?
            sleep 10 # make sure the connection is really established
            if network_status.connected?
              block.call
            end
          end
        rescue => e
          @logger.error "#{e.class} #{e}"
        ensure
          device.disconnect
        end
      end
      
    end
  end
  
  def upload
    host = StopaMonitorConfig::HOST
    login = StopaMonitorConfig::LOGIN
    password = StopaMonitorConfig::PASSWORD
    remote_working_dir = StopaMonitorConfig::REMOTE_WORKING_DIR

    files_to_transfer = Dir.glob File.join(@snapshot_dir, '*') 
    files_to_transfer.reject!{|f| f =~ /\.log\Z/}
    
    @logger.info "About to upload data to '#{host}' as user '#{login}'"

    begin    
      ftp = Net::FTP.new host
      ftp.login login, password
      @logger.info 'connection established'
      
      determine_reverse_ssh_tunnel_port ftp
      remote_snapshot_dir = File.join remote_working_dir, @timestamp
      ftp.mkdir remote_snapshot_dir
      @logger.debug "created remote upload dir #{remote_snapshot_dir}"
      
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
      @logger.error "ftp upload problem: #{e.class} #{e}"
    ensure
      begin
        ftp.close
      rescue
      end
    end
    
    @logger.info 'upload finished'
  end
  
  def establish_reverse_ssh_tunnel_if_required_by_server
    return unless @reverse_ssh_tunnel_port
    
    @logger.info "about to establish reverse SSH tunnel to #{StopaMonitorConfig::HOST} on port #{@reverse_ssh_tunnel_port}"
    begin
      ssh = Net::SSH.start StopaMonitorConfig::HOST, StopaMonitorConfig::LOGIN
      ssh.forward.remote 22, 'localhost', @reverse_ssh_tunnel_port
      started_at = Time.now
      # stay connected for 1 hour, check elapsed time every 60 seconds
      ssh.loop(60) do
        diff = Time.now - started_at
        diff < 3600
      end
      
    rescue => e
      @logger.error "reverse ssh problem: #{e.class} #{e}"
      begin
        ssh.close
      rescue
      end
    end
    
  end
  
  def cleanup
    OldSnapshotsCleaner.new(@logger, WORKING_DIR).run
  end
  
  def close_and_reboot_if_necessary
    @logger.info "closing snapshot"
    
    if @health_check_ok
      @logger.close
    else
      @logger.warn "rebooting device due to health check results"
      @logger.close
      if in_production_mode?
        exec "sudo reboot"
      end
    end
  end
  
  private 
  
  # we are in production mode if this job is scheduler via crontab
  def in_production_mode?
    `crontab -l`.split("\n").find do |l| 
      l[0] != '#' && l.include?('stopa-monitor/src/run.rb')
    end
  end
  
  def determine_reverse_ssh_tunnel_port ftp
    @logger.debug "checking if server asks us to establish reverse ssh tunnel"
    expected_file = File.join StopaMonitorConfig::REMOTE_WORKING_DIR, 'REVERSE_SSH_TUNNEL_PORT_*'
    first_line = ftp.list(expected_file).first
    #  "-rw-rw-r--   1 stopa_monitor3 stopa_monitor3        0 Jun  4 19:21 /home/stopa_monitor3/snapshots/REVERSE_SSH_TUNNEL_PORT_4321"
    if first_line
      port_no = first_line.match(/REVERSE_SSH_TUNNEL_PORT_(\d+)/)[1]
      @reverse_ssh_tunnel_port = port_no.to_i
      @logger.info "server asked us to establish reverse ssh tunnel on port #{@reverse_ssh_tunnel_port.inspect}"
    else
      @logger.debug "server did not want us to establish reverse ssh tunnel"
    end
  end
end