require 'serialport'
require 'time'

class SimCardSMS
  # sms can be gathered from usb modem (=ttyUSBx) only when device is not connected to network (tty lock)
  OUTPUT_FILE = 'sms.txt'
  
  GSM_MODEM_DEV = '/dev/ttyUSB0'
  SMS_CENTER_NO = "+421905303303" # orange.sk Short message service center

  def initialize logger, snapshot_dir
    @logger = logger
    @output_file = File.join snapshot_dir, OUTPUT_FILE
    @logger.info "Initialized SimCardSMS"
  end
  
  def capture
    begin
      gsm_modem = GSM.new :port => GSM_MODEM_DEV, :speed => 9600, :sms_center_no => SMS_CENTER_NO
      File.open(@output_file, 'w') do |f|
        gsm_modem.messages.each do |msg|
          msg_text = "#{msg.id} - #{msg.time} - #{msg.sender} - #{msg.message}"
          @logger.info "received sms message: #{msg_text}"
          f.puts msg_text
          msg.delete
          @logger.info "deleted sms message: #{msg.id}"
        end
      end 
    rescue => e
      @logger.error "SimCardSMS.capture #{e} #{e.class}"
    end
  end
  
  # following code is taken from
  # http://www.dzone.com/snippets/send-and-receive-sms-text
  class GSM

    def initialize(options = {})
      @port = SerialPort.new(options[:port], options[:speed])
      cmd("AT")
      # Set to text mode
      cmd("AT+CMGF=1")
      # Set SMSC number
      cmd("AT+CSCA=\"#{options[:sms_center_no]}\"")    
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

end