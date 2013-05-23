require 'rubygems'
require 'amqp'

EventMachine.run do
	host = ENV["server"]
	queuename = ENV["queuename"] || "tests"
	size = ENV["size"].to_i
	puts "size: #{size}"
	total_messages = 0
	AMQP.connect :host=> host do |connection|
		puts "Connecting to amqp host"
		channel = AMQP::Channel.new(connection)
		channel.on_error do |ch, channel_close|
  			raise "Channel-level exception: #{channel_close.reply_text}"
		end
		def sendmessage(exchange, i, size)
			if(i == size)
				EventMachine.stop { exit }
				return
			end
			EventMachine.next_tick do
				puts "begin publish #{i}"
				routes = ["caminho.a", "caminho.b"]
				exchange.publish("Hello #{i}, direct exchanges world!", :routing_key => routes[i % routes.length]) do
					
				puts "done publish #{i}"
					sendmessage exchange, i + 1, size
				end
			end
		end
		channel.topic(queuename, :auto_delete=>false, :durable=>true) do |exchange|
			
		sendmessage(exchange, 0, size)	
			
		end
		puts "end send"
		
	end
end
