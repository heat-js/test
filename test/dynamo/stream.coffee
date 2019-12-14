
import { start } from '../../src/dynamodb/index'

describe 'DynamoDB stream', ->

	listener = jest.fn()

	dynamo = start {
		path: './aws/dynamodb.yml'
		stream: {
			test: [ listener ]
		}
	}

	client = dynamo.documentClient()

	it 'should emit the change stream record to the subscribers', ->
		await client.put {
			TableName: 'test'
			Item: {
				id: 'test'
			}
		}
		.promise()

		expect listener
			.toHaveBeenCalled()
