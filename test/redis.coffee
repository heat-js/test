
import { start } 	from '../src/redis'
import AWS 			from 'aws-sdk'

describe 'Test Redis server', ->

	clients = []
	servers = []
	promises = [ 1 ].map (i) ->
		redis = start { port: 6379 }
		clients.push redis.client()
		servers.push redis

	it 'should be able to connect and store an item in', ->
		result = await new Promise (resolve, reject) ->
			clients[0].SET 'test', 'test', (error) ->
				clients[0].GET 'test', (error, data) ->
					resolve data

		console.log result
