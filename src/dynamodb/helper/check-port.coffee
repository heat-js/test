
import net from 'net'

export default (port) ->
	return new Promise (resolve, reject) ->
		server = net.createServer()
		server.once 'error', (error) ->
			if error.code is 'EADDRINUSE'
				resolve false
			else
				reject error

		server.once 'listening', ->
			server.close()
			resolve true

		server.listen port
