
import { start } 	from '../src/dynamodb/server'
import filelock 	from '../src/dynamodb/helper/filelock'
import AWS 			from 'aws-sdk'

describe 'Test DynamoDB server', ->

	dynamo = start {
		path: './aws/dynamodb.yml'
	}

	it 'should spawned a local dynamodb instance', ->
		expect dynamo
			.toHaveProperty 'dynamodb'

		expect dynamo
			.toHaveProperty 'documentClient'

		dynamodb = dynamo.dynamodb()
		client 	 = dynamo.documentClient()

		expect dynamodb instanceof AWS.DynamoDB
			.toBe true

		expect client instanceof AWS.DynamoDB.DocumentClient
			.toBe true

		expect typeof client.service.endpoint.port
			.toBe 'number'

	it 'should acquire multiple locks without error', ->
		promises = [0..9].map (i) ->
			unlock = await filelock()
			unlock()
			return i

		results = await Promise.all promises

		expect results.length
			.toBe 10
