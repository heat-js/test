
import fs				from 'fs'
import AWS				from 'aws-sdk'
import dynamoDbLocal	from 'dynamo-db-local'
import YAML				from 'js-yaml'
import portFinder 		from './helper/port-finder'

export default class DynamoDBServer

	constructor: (config = {}) ->
		@instances = {
			dynamos: []
			clients: []
		}

		@config = Object.assign {}, {
			region: 	'eu-west-1'
			seed: 		{}
			timeout: 	30 * 1000
		}, config

		@port = @config.port

	start: ->
		tables = @_getTables @config.path

		dynamoProcess = null

		beforeAll =>
			if not @config.port
				{ unlock, port } = await portFinder()

				@unlock = unlock
				@port	= port

				for dynamo in @instances.dynamos
					dynamo.endpoint.port = @port

				for client in @instances.clients
					client.service.endpoint.port = @port

			dynamoProcess = await dynamoDbLocal.spawn {
				port: @port
			}

			dynamo = @_createDynamo()
			client = @_createDocumentClient()

			for table in tables
				await dynamo.createTable(table).promise()

			for TableName, Items of @config.seed
				for Item in Items
					await client.put {
						TableName
						Item
					}
					.promise()
		, @config.timeout

		afterAll =>
			await dynamoProcess.kill()
			if @unlock
				await @unlock()
		, @config.timeout

		return {
			dynamodb: =>
				return @_createDynamo()
			documentClient: =>
				return @_createDocumentClient()
		}

	_getTables: (path) ->
		yaml      = fs.readFileSync path
		resources = YAML.safeLoad yaml

		tables = []

		for name, resource of resources
			if resource.Type isnt 'AWS::DynamoDB::Table'
				continue

			properties = Object.assign {}, resource.Properties

			properties.BillingMode = 'PAY_PER_REQUEST'

			delete properties.TimeToLiveSpecification
			delete properties.PointInTimeRecoverySpecification

			tables.push properties

		return tables

	_createDynamo: ->
		instance = new AWS.DynamoDB {
			apiVersion: 		'2016-11-23'
			endpoint: 			"http://localhost:#{@port or 80}"
			region: 			@config.region
			sslEnabled:			false
			accessKeyId:		'fake'
			secretAccessKey:	'fake'
		}

		@instances.dynamos.push instance

		return instance

	_createDocumentClient: ->
		client = new AWS.DynamoDB.DocumentClient {
			service: @_createDynamo()
		}

		@instances.clients.push client

		return client


export start = (config = {}) ->
	server = new DynamoDBServer config
	return server.start()
