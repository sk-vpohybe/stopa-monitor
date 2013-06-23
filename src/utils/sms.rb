# code to list SMS messages from modem, taken from
# http://www.dzone.com/snippets/send-and-receive-sms-text

# usage: 
# ruby sms.rb
# ruby sms.rb delete_all

require 'serialport'
require 'time'

class GSM
  SMSC = "+421905303303" # orange.sk Short message service center

  def initialize(options = {})
    @port = SerialPort.new(options[:port], options[:speed])
    cmd("AT")
    # Set to text mode
    cmd("AT+CMGF=1")
    # Set SMSC number
    cmd("AT+CSCA=\"#{SMSC}\"")    
  end
  
  def close
    @port.close
  end
  
  def cmd(cmd)
    @port.write(cmd + "\r")
    wait
  end
  
  def wait
    buffer = ''
    while IO.select([@port], [], [], 0.25)
      chr = @port.getc.chr;
      buffer += chr
    end
    buffer
  end

  def send_sms(options)
    cmd("AT+CMGS=\"#{options[:number]}\"")
    cmd("#{options[:message][0..140]}#{26.chr}\r\r")
    sleep 3
    wait
    cmd("AT")
  end
  
  class SMS
    attr_accessor :id, :sender, :message, :connection
    attr_writer :time
    
    def initialize(params)
      @id = params[:id]; @sender = params[:sender]; @time = params[:time]; @message = params[:message]; @connection = params[:connection]
    end
    
    def delete
      @connection.cmd("AT+CMGD=#{@id}")
    end
    
    def time
      @time.to_s
    end
  end
  
  def messages
    sms = cmd("AT+CMGL=\"ALL\"")
    msgs = sms.scan(/\+CMGL\:\s*?(\d+)\,.*?\,\"(.+?)\"\,.*?\,\"(.+?)\".*?\n(.*)/)
    return nil unless msgs
    msgs.collect!{ |m| GSM::SMS.new(:connection => self, :id => m[0], :sender => m[1], :time => m[2], :message => m[3].chomp) } rescue nil
  end
end


p = GSM.new(:port => '/dev/ttyUSB0', :speed => 9600)

# Send a text message
# p.send_sms(:number => destination_number, :message => "Test at #{Time.now}")

# Read text messages from phone
p.messages.each do |msg|
  puts "#{msg.id} - #{msg.time} - #{msg.sender} - #{msg.message}"
  msg.delete if ARGV[0] == 'delete_all'
end
