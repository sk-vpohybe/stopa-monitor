# [program:stopa_monitor_button]
# command=ruby /home/pi/Repositories/stopa-monitor/src/run_by_button.rb
# autostart=true
# autorestart=true
# stderr_logfile = /var/log/supervisord/stopa_monitor_button.log
# stdout_logfile = /var/log/supervisord/stopa_monitor_button.log

require 'pi_piper'
include PiPiper

led = PiPiper::Pin.new(:pin => 17, :direction => :out)
after :pin => 18, :goes => :high do
10.times do
  led.on
  sleep 0.1
  led.off
  sleep 0.1
end

led.on
`ruby /home/pi/Repositories/stopa-monitor/src/run.rb`

10.times do
  led.on
  sleep 0.1
  led.off
  sleep 0.1
end

end

PiPiper.wait