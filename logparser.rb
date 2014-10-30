requests = {
#	"/api/users/{user_id}/count_pending_messages" => {},
#	"/api/users/{user_id}/get_messages" => {},
#	"/api/users/{user_id}/get_friends_progress" => {},
#	"/api/users/{user_id}/get_friends_score" => {},
	"/api/users/{user_id}" => {}
}

rgx = /(?<datetime>[0-9.:T+-]*)\sheroku.*method=(?<method>.*)\spath=(?<path>.*)\shost=(?<host>.*)\sfwd="(?<fwd>.*)"\sdyno=(?<dyno>.*)\sconnect=(?<ctime>\d+)ms\sservice=(?<stime>\d+)ms\sstatus=(?<status>\d+)\sbytes=(?<bytes>\d+)/i

f = File.open("sample.log","r").each do |line|
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

puts requests

printf("%-50s%-10s%-8s%-10s%-13s%-10s%-15s","PATH","METHOD","HITS","MEAN(ms)","MEDIAN(ms)","MODE(ms)","MAX_RESP_DYNO\n\n")

requests.each do |path,methods|
	methods.each do |method,stats|
		printf("%-50s%-10s%-8i",path,method,stats[:hits])
		printf("%-10.2f%-13.2f%-10i",stats[:mean],stats[:median],stats[:mode])
		printf("%-10s",stats[:max_dyno].first.to_s + " with " + stats[:max_dyno].last.to_s)
		puts
	end
end

