
import { start } 	from '../src/dynamodb/server'
import filelock 	from '../src/dynamodb/helper/filelock'
import AWS 			from 'aws-sdk'

describe 'Test DynamoDB server', ->

	servers = []
	promises = [1..3].map (i) ->
		dynamo = start {
			path: './aws/dynamodb.yml'
		}
		servers.push dynamo

	it 'should check all spawned dynamodb instances', ->
		ports = []
		servers.map (dynamo) ->
			expect dynamo
				.toHaveProperty 'dynamodb'

			expect dynamo
				.toHaveProperty 'documentClient'

			dynamodb = dynamo.dynamodb()
			client 	 = dynamo.documentClient()
			port 	 = client.service.endpoint.port

			expect dynamodb instanceof AWS.DynamoDB
				.toBe true

			expect client instanceof AWS.DynamoDB.DocumentClient
				.toBe true

			expect typeof port
				.toBe 'number'

			ports.push port

		# ---------------------------------------------------------
		# Check if the all instances have a different port

		expect ports.length
			.toBe servers.length

		unique = [...new Set ports]

		expect unique.length
			.toBe ports.length
