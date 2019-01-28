
import AWS				from 'aws-sdk'
import dynamoDbLocal	from 'dynamo-db-local'
import YAML				from 'yamljs'

export start = (params = {}) ->

	params = Object.assign {
		port: 9000
		region: 'eu-west-1'
	}, params

	resources = YAML.load params.path
	tables = []

	for name, resource of resources

		if resource.Type is 'AWS::DynamoDB::Table'

			properties = Object.assign {
				ProvisionedThroughput: {
					ReadCapacityUnits: 1
					WriteCapacityUnits: 1
				}
			}, resource.Properties

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

	afterAll ->
		await dynamoProcess.kill()

	return client
