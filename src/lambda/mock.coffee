
export default class LambdaMock

	constructor: (@lambdas = {}) ->

	on: (name, callback) ->
		@lambdas[ name ] = callback

	invoke: jest.fn ({ service, name, payload }) ->
		if name and service
			name = "#{ service }__#{ name }"

		callback = @lambdas[ name ]
		if callback
			return callback payload

	invokeAsync: jest.fn (params) ->
		await @invoke params
		return @

export createLambdaMock = (lambdas) ->
	return new LambdaMock lambdas
