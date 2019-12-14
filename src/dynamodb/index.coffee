
import DefinitionParser	from './definition-parser'
import FileSystem		from './file-system'
import Migrator			from './migrator'
import PortFinder		from './port-finder'
import Seeder			from './seeder'
import Server			from './server'
import StreamEmitter	from './stream-emitter'

export start = (config = {}) ->
	parser		= new DefinitionParser config.path
	definitions = parser.parseFiles config.path

	fs 			= new FileSystem
	portFinder	= new PortFinder fs
	server		= new Server config.region
	stream 		= new StreamEmitter config.stream, definitions
	migrator	= new Migrator server.dynamodb(), definitions
	seeder		= new Seeder server.documentClient(), config.seed

	timeout		= config.timeout or 30 * 1000

	beforeAll ->
		port = config.port or await portFinder.find()

		await server.listen port
		await migrator.migrate()
		await seeder.seed()

	, timeout

	afterAll ->
		await server.destroy()
		await portFinder.release()

	, timeout

	return {
		documentClient: ->
			client = server.documentClient()
			stream.attach client

			return client

		dynamodb: ->
			return server.dynamodb()
	}
