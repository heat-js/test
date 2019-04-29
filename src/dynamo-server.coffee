
import AWS				from 'aws-sdk'
import dynamoDbLocal	from 'dynamo-db-local'
import YAML				from 'yamljs'

export start = (params = {}) ->

	params = Object.assign {
		port: 		9000
		region: 	'eu-west-1'
		seed: 		{}
		timeout: 	30 * 1000
	}, params

	resources = YAML.load params.path
	tables = []

	for name, resource of resources
		if resource.Type isnt 'AWS::DynamoDB::Table'
			continue

		# throughput = {
		# 	ProvisionedThroughput: {
		# 		ReadCapacityUnits:  100
		# 		WriteCapacityUnits: 100
		# 	}
		# }

		# properties = Object.assign {}, throughput, resource.Properties
		properties = Object.assign {}, resource.Properties

		# if properties.LocalSecondaryIndexes
			# for entry, i in properties.LocalSecondaryIndexes
				# properties.LocalSecondaryIndexes[i] = Object.assign {}, throughput, entry

		# if properties.GlobalSecondaryIndexes
			# for entry, i in properties.GlobalSecondaryIndexes
				# properties.GlobalSecondaryIndexes[i] = Object.assign {}, throughput, entry

		# delete properties.BillingMode
		delete properties.TimeToLiveSpecification
		delete properties.PointInTimeRecoverySpecification

		tables.push properties

	dbOptions = {
		apiVersion: 		'2012-08-10'
		endpoint: 			"http://localhost:#{params.port}"
		region: 			params.region
		accessKeyId: 		'fake'
		secretAccessKey: 	'fake'
	}

	dynamo = new AWS.DynamoDB dbOptions
	client = new AWS.DynamoDB.DocumentClient {
		service: dynamo
	}

	dynamoProcess = null

	beforeAll ->
		dynamoProcess = await dynamoDbLocal.spawn {
			port: params.port
		}

		for table in tables
			await dynamo.createTable(table).promise()

		for TableName, Items of params.seed
			for Item in Items
				await client.put {
					TableName
					Item
				}
				.promise()
	, params.timeout

	afterAll ->
		await dynamoProcess.kill()
	, params.timeout

	return {
		dynamodb: ->
			return new AWS.DynamoDB dbOptions
		documentClient: ->
			return new AWS.DynamoDB.DocumentClient {
				service: new AWS.DynamoDB dbOptions
			}
	}
