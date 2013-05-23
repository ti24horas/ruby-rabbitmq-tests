require 'rubygems'
require 'amqp'

EventMachine.run do
	def sendbatch(host, queuename, size = 1000)
		AMQP.connect :host=> host do |connection|
			puts "Connecting to amqp host"
			channel = AMQP::Channel.new(connection)
			channel.on_error do |ch, channel_close|
	  			raise "Channel-level exception: #{channel_close.reply_text}"
			end
			
			exchange = channel.topic("pub/sub")

			size.times do |i|
				exchange.publish "hello world" * 10000, :routing_key => queuename
				puts "message #{i} sent"
				sleep 0.5
			end
			connection.close
			EventMachine.stop { 
				puts "finish"
					exit 
					}
		end
	end

	def subscribe(host, queuename)
		AMQP.connect :host=> host do |connection|
			puts "Connecting to amqp host"
			channel = AMQP::Channel.new(connection)
			channel.on_error do |ch, channel_close|
	  			raise "Channel-level exception: #{channel_close.reply_text}"
			end
			channel.prefetch(1)

			total_messages = 0
			exchange = channel.topic("pub/sub")
			queue = channel.queue(queuename, :auto_delete => true).bind(exchange).subscribe do |payload|
				total_messages = total_messages + 1
				puts " #{total_messages} - received a message: #{payload}."
				EventMachine.stop { 
					exit 
					} if total_messages == 100000
			end

			puts "connected on queue #{queue.name}"
		end
	end
	host = "rabbitmq.ti24h.net"
	puts ENV["mode"]
	if ENV["mode"] == "publisher"
		sendbatch(host, "mytests.helloworld", 1000)
	else
		subscribe host, "mytests.helloworld"
	end
end