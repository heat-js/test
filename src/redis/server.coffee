
import RedisServer		from 'redis-server'
import redis			from 'redis'

export default class Server

	constructor: ->
		@clients	= []
		@port		= 80

	flushData: ->
		return new Promise (resolve, reject) =>
			client = @client()
			client.flushall (error1) ->
				client.quit (error2) ->
					error = error1 or error2
					if error then reject error
					else resolve()

	listen: (@port) ->
		for client in @clients
			client.address = "#{ client.address.split(':')[0] }:#{ @port }"
			client.options.port = @port
			client.connection_options.port = @port

		@process = new RedisServer { port: @port }
		await @process.open()
		await @flushData()

	destroy: ->
		await @flushData()
		await Promise.all @clients.map (client) ->
			return new Promise (resolve, reject) ->
				client.quit (error) ->
					if error then reject error
					else resolve()

		if @process
			await @process.close()

	client: ->
		client = redis.createClient {
			port: 						@port
			string_numbers:				true
			socket_keepalive:			false
			socket_initial_delay:		0
			no_ready_check:				false
			retry_unfulfilled_commands:	false

			# retry_strategy: (options) ->
			# 	return

		}

		client.on 'error', (error) ->
			# if error.code isnt 'NR_FATAL'
			# 	console.error error

		@clients.push client

		return client
