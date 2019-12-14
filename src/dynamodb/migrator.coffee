
export default class Migrator

	constructor: (@db, @definitions) ->

	migrate: ->
		for definition in @definitions
			await @db.createTable definition
				.promise()
