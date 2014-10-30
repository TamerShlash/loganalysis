require 'time'

class LogRequest
	attr_reader :datetime, :path, :method, :host, :fwd,
							:dyno, :connect_time, :service_time, :status, :size
	@@rgx = /(?<datetime>[0-9.:T+-]*)\sheroku.*method=(?<method>.*)\spath=(?<path>.*)\shost=(?<host>.*)\sfwd="(?<fwd>.*)"\sdyno=(?<dyno>.*)\sconnect=(?<ctime>\d+)ms\sservice=(?<stime>\d+)ms\sstatus=(?<status>\d+)\sbytes=(?<bytes>\d+)/i
	def initialize line
		req = line.match(@@rgx)
		@datetime = Time.parse(req["datetime"])
		@method = req["method"]
		@path = req["path"].gsub(/\d+/,"{digits}")
		@host = req["host"]
		@fwd = req["fwd"]
		@dyno = req["dyno"]
		@connect_time = req["ctime"].to_i
		@service_time = req["stime"].to_i
		@status = req["status"]
		@size = req["bytes"].to_i
	end
end

