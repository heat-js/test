
import { start } from '../../src/dynamodb/index'

describe 'DynamoDB stream', ->

	listener = jest.fn()

	dynamo = start {
		path: './aws/dynamodb.yml'
		stream: {
			test: listener
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
			.toHaveBeenCalledTimes 1

		await client.update {
			TableName: 'test'
			Key: { id: 'test' }
			UpdateExpression: 'set #field = :value'
			ExpressionAttributeNames:
				'#field': 'field'
			ExpressionAttributeValues:
				':value': 'value'
		}
		.promise()

		expect listener
			.toHaveBeenCalledTimes 2

		await client.transactWrite {
			TransactItems: [
				{
					Put:
						TableName: 'test'
						Item:
							id: 'test-2'
				}
			]
		}
		.promise()

		expect listener
			.toHaveBeenCalledTimes 3
