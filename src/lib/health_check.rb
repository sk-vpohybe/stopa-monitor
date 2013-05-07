class HealthCheck
  LOW_DISK_MB = 30
  LOW_RAM_MB = 30 # mb
  
  attr_reader :ok
  
  def initialize logger, capture_devices, transfer_devices
    @logger = logger
    @logger.debug "starting Health Check"
    @detected_capture_devices = capture_devices
    @detected_transfer_devices = transfer_devices
  end
  
  def run
    t = (uptime / 3600).round 2
    @logger.debug "uptime: #{t} hours"
    
    hd = free_disk_space
    @logger.debug "free disk space: #{hd} MB"
    
    ram = free_ram_space
    @logger.debug "free RAM space: #{ram} MB"
    
    check_ok = true
    if(hd < LOW_DISK_MB)
      check_ok = false
      @logger.warn "free disk space is only #{hd} MB"
    end
    
    if(hd < LOW_RAM_MB)
      check_ok = false
      @logger.warn "free RAM space is only #{ram} MB"
    end   
    
    if missing_capture_devices.size > 0
      check_ok = false
      @logger.warn "missing capture device(s): #{missing_capture_devices.join(' ')}"
    end
    
    if missing_transfer_devices.size > 0
      check_ok = false
      @logger.warn "missing transfer device(s): #{missing_transfer_devices.join(' ')}"
    end
    
    if check_ok
      @ok = true
      @logger.info "Health Check OK"
    else
      @ok = false
    end
  end
  
  private
  
  def uptime
    # 614.55 545.2
    uptime_in_seconds = `cat /proc/uptime`.split(' ').first.to_i
    return uptime_in_seconds
  end
  
  def free_disk_space
    # Filesystem     1K-blocks    Used Available Use% Mounted on
    # /dev/root        1804128 1574540    137940  92% /
    free_disk_space_in_mb = `df`.split("\n")[1].split(' ')[-3].to_i / 1000
    return free_disk_space_in_mb
  end
  
  def free_ram_space
    free_ram_in_mb = `free -m`.split("\n")[1].split(" ")[3].to_i
    return free_ram_in_mb
  end
  
  def missing_capture_devices
    StopaMonitorConfig::ATTACHED_CAPTURE_DEVICES - @detected_capture_devices
  end
  
  def missing_transfer_devices
    StopaMonitorConfig::ATTACHED_TRANSFER_DEVICES - @detected_transfer_devices
  end 
end