require 'optparse'

# Parse command line options
options = {}
optparser = OptionParser.new do |opts|
	opts.banner = "Usage: logparse.rb [options]"
	opts.on('-l', '--logfile FILE', 'The logfile to analys') { |v| options[:logfile] = v }
	opts.on('-r', '--requests FILE', 'Contains requests to analys, one per line') do |v|
		options[:requests] = v
	end
end
optparser.parse!
abort optparser.help unless options[:logfile] and options[:requests]

# Import requests to be analys
requests = {}
File.open(options[:requests],'r') do |f|
	f.each { |l| requests[l.gsub(/\d+/,"{user_id}").strip] = {} }
end

# Collect data from logfile
rgx = /(?<datetime>[0-9.:T+-]*)\sheroku.*method=(?<method>.*)\spath=(?<path>.*)\shost=(?<host>.*)\sfwd="(?<fwd>.*)"\sdyno=(?<dyno>.*)\sconnect=(?<ctime>\d+)ms\sservice=(?<stime>\d+)ms\sstatus=(?<status>\d+)\sbytes=(?<bytes>\d+)/i

f = File.open(options[:logfile],"r").each do |line|
	request = line.match(rgx)
	path = request["path"].gsub(/\d+/,"{user_id}")
	method = request["method"]
	dyno = request["dyno"]
	if requests[path]
		requests[path][method] = { hits:0,time:0,times:[],dynos:{} } unless requests[path][method]
		requests[path][method][:hits] += 1
		requests[path][method][:time] += request["ctime"].to_i + request["stime"].to_i
		requests[path][method][:times] << request["ctime"].to_i + request["stime"].to_i
		if requests[path][method][:dynos][dyno]
			requests[path][method][:dynos][dyno] += 1
		else
			requests[path][method][:dynos][dyno] = 1
		end
	end
end
f.close

# Process
requests.each do |path,methods|
	methods.each do |method,stats|
		stats[:mean] = stats[:time] / stats[:hits].to_f
		stats[:times].sort!
		hits = stats[:hits]
		if hits.odd?
			stats[:median] = stats[:times][hits/2]
		else
			stats[:median] = (stats[:times][hits/2] + stats[:times][(hits/2)-1])/2.0
		end
		stats[:mode] = stats[:times].group_by { |i| i }.max_by { |k,v| v.length }.first
		stats[:max_dyno] = stats[:dynos].max_by { |k,v| v }
	end
end


# Output
printf("%-50s%-10s%-8s%-10s%-13s%-10s%-15s\n\n",
			 "PATH","METHOD","HITS","MEAN(ms)","MEDIAN(ms)","MODE(ms)","MAX RESP DYNO")
requests.each do |path,methods|
	methods.each do |method,stats|
		printf("%-50s%-10s%-8i",path,method,stats[:hits])
		printf("%-10.2f%-13.2f%-10i",stats[:mean],stats[:median],stats[:mode])
		printf("%-6s with %-5i",stats[:max_dyno].first,stats[:max_dyno].last)
		puts
	end
end
