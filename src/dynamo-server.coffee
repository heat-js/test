
import AWS				from 'aws-sdk'
import dynamoDbLocal	from 'dynamo-db-local'
import YAML				from 'yamljs'

export start = (params = {}) ->

	params = Object.assign {
		port: 9000
		region: 'eu-west-1'
		seed: {}
	}, params

	resources = YAML.load params.path
	tables = []

	for name, resource of resources
		if resource.Type isnt 'AWS::DynamoDB::Table'
			continue

		throughput = {
			ProvisionedThroughput: {
				ReadCapacityUnits: 100
				WriteCapacityUnits: 100
			}
		}

		properties = Object.assign resource.Properties, throughput

		if properties.LocalSecondaryIndexes
			for index in properties.LocalSecondaryIndexes
				Object.assign index, throughput

		if properties.GlobalSecondaryIndexes
			for index in properties.GlobalSecondaryIndexes
				Object.assign index, throughput

		delete properties.BillingMode
		delete properties.TimeToLiveSpecification
		delete properties.PointInTimeRecoverySpecification

		tables.push properties

	dynamo = new AWS.DynamoDB {
		apiVersion: 		'2012-08-10'
		endpoint: 			"http://localhost:#{params.port}"
		region: 			params.region
		accessKeyId: 		'fake'
		secretAccessKey: 	'fake'
	}

	client = new AWS.DynamoDB.DocumentClient { service: dynamo }

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

	afterAll ->
		await dynamoProcess.kill()

	return client
