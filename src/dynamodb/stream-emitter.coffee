
import AWS from 'aws-sdk'

export default class StreamEmitter

	constructor: (@listeners = {}, @definitions) ->

	attach: (client) ->
		transactWrite	= client.transactWrite.bind client
		update			= client.update.bind client
		put				= client.put.bind client
		deleteFn		= client.delete.bind client

		client.transactWrite	= (params) => return @transactWrite client, transactWrite, params
		client.update			= (params) => return @update client, update, params
		client.put 				= (params) => return @put client, put, params
		client.delete 			= (params) => return @delete client, deleteFn, params

	hasListeners: (table) ->
		listeners = @listeners[ table ]

		return (
			( Array.isArray listeners ) or
			( typeof listeners is 'function' )
		)

	emit: (table, Key, OldImage, NewImage) ->
		if not @hasListeners table
			return

		Key			= Key and AWS.DynamoDB.Converter.marshall Key
		OldImage	= OldImage and AWS.DynamoDB.Converter.marshall OldImage
		NewImage	= NewImage and AWS.DynamoDB.Converter.marshall NewImage

		listeners = @listeners[ table ]
		if not Array.isArray listeners
			listeners = [ listeners ]

		return Promise.all listeners.map (listener) ->
			return listener {
				Records: [
					{ dynamodb: { Keys: Key, OldImage, NewImage } }
				]
			}

	getItem: (client, TableName, Key) ->
		result = await client.get { Key, TableName }
			.promise()

		return result.Item

	getPrimaryKey: (table, item) ->
		properties = @definitions.find (def) ->
			return def.TableName is table

		if not properties
			throw new Error 'Could not find key schema for table: ' + table

		key = {}
		for schema in properties.KeySchema
			key[schema.AttributeName] = item[schema.AttributeName]

		return key

	update: (client, update, params) ->
		request = update params

		{ Key, TableName } = params

		if not @hasListeners TableName
			return request

		return {
			promise: =>
				OldImage	= await @getItem client, TableName, Key
				result		= await request.promise()
				NewImage	= await @getItem client, TableName, Key

				await @emit TableName, Key, OldImage, NewImage

				return result
		}

	put: (client, put, params) ->
		request = put params

		{ TableName, Item } = params

		if not @hasListeners TableName
			return request

		Key	= @getPrimaryKey TableName, Item

		return {
			promise: =>
				OldImage	= await @getItem client, TableName, Key
				result		= await request.promise()
				NewImage	= await @getItem client, TableName, Key

				await @emit TableName, Key, OldImage, NewImage

				return result
		}

	delete: (client, deleteFn, params) ->
		request = deleteFn params

		{ TableName, Key } = params

		if not @hasListeners TableName
			return request

		return {
			promise: =>
				OldImage	= await @getItem client, TableName, Key
				result		= await request.promise()
				NewImage	= await @getItem client, TableName, Key

				await @emit TableName, Key, OldImage, NewImage

				return result
		}

	filterTransactItems: (items) ->
		return items
			.map (item) =>
				if item.Put
					return {
						table:	item.Put.TableName
						key:	@getPrimaryKey item.Put.TableName, item.Put.Item
					}

				if item.Delete
					return {
						table:	item.Delete.TableName
						key:	item.Delete.Key
					}

				return {
					table:	item.Update.TableName
					key:	item.Update.Key
				}

			.filter (item) =>
				return @hasListeners item.table


	transactWrite: (client, transactWrite, params) ->
		request = transactWrite params
		return {
			promise: =>
				items = @filterTransactItems params.TransactItems

				oldData = await Promise.all items.map ({ table, key }) =>
					return @getItem client, table, key

				result = await request.promise()

				newData = await Promise.all items.map ({ table, key }) =>
					return @getItem client, table, key

				await Promise.all [ 0...items.length ].map (index) =>
					table		= items[index].table
					key			= items[index].key
					oldImage	= oldData[index]
					newImage	= newData[index]

					return @emit table, key, oldImage, newImage

				return result
		}
