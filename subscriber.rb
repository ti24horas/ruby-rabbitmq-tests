require 'rubygems'
require 'amqp'

EventMachine.run do
	host = ENV["server"]
	queuename = ENV["queuename"]
	AMQP.connect :host=> host do |connection|
		puts "Connecting to amqp host"
		channel1 = AMQP::Channel.new(connection)
		channel1.prefetch(1000)


		queue1 = channel1.queue("mytests", :durable=>true, :auto_delete => false)
		exchange1 = channel1.topic(queuename, :auto_delete=>false, :durable=>true)

		channel1.on_error do |ch, channel_close|
				raise "Channel-level exception: #{channel_close.reply_text}"
		end
		
		total_messages = 0
		queue1.bind(exchange1, :routing_key=> "caminho.a").subscribe(:ack=>true) do |meta, msg|
			total_messages = total_messages + 1
			puts " #{total_messages} - routing key received a message: #{msg}."
			meta.ack true
		end

		channel2 = AMQP::Channel.new(connection)
		channel2.prefetch(1000)


		queue2 = channel2.queue("mytests2", :durable=>true, :auto_delete => false, :ack=>true)
		#exchange2 = channel2.topic(queuename + "adsa", :auto_delete=>false, :durable=>true)

		channel2.on_error do |ch, channel_close|
				raise "Channel-level exception: #{channel_close.reply_text}"
		end
		
		total_messages = 0
		queue2.bind(exchange1, :routing_key=>"caminho.*").subscribe(:ack=>true) do |meta, msg|
			total_messages = total_messages + 1
			puts " #{total_messages} - (from *) received a message: #{msg}."
			meta.ack true
		end

		channel3 = AMQP::Channel.new(connection)
		channel3.prefetch 1000
		channel3.queue("mytests2").bind(exchange1, :routing_key=>"caminho.b").subscribe(:ack=>true) do |meta, msg|
			total_messages = total_messages + 1
			puts " #{total_messages} - (from *) received a message: #{msg}."
			meta.ack true
		end
		
	end
	
end