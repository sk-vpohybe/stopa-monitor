require 'logger'

class OpenLogger < Logger
  attr_reader :logfile_path
  
  def initialize *args
  	@logfile_path = args.first
  	super *args
  end
end