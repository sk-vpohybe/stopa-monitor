require 'file_utils'

class OldSnapshotsCleaner
  CLEANUP_AGE_DAYS = 20 
  CLEANUP_AGE_SECONDS = CLEANUP_AGE_DAYS * 24 * 60 * 60
  
  def initialize logger, working_dir_with_snapshots
    @logger = logger
    @working_dir = working_dir_with_snapshots
  end
  
  def run
    candidates_path = File.join @working_dir, '*'
    snapshot_dirs_to_delete = Dir.glob(candidates_path).select do |p|
      if File.directory?(p)
        File.ctime(p) < (Time.now - CLEANUP_AGE_SECONDS)
      end
    end
    
    @logger.info "OldSnapshotsCleaner: about to delete following snapshots:\n #{snapshot_dirs_to_delete.join("\n")}"
    snapshot_dirs_to_delete.each do |d|
      FileUtils.rm_rf d
    end
  end
end