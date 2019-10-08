
import filelock 	from './filelock'
# import getPort 		from 'get-port'
import checkPort 	from './check-port'

randomPort = ->
	min = 32768
	max = 65535
	return Math.floor Math.random() * (max - min) + min

export default ->

	times = 10
	while times--
		port = randomPort()
		open = await checkPort port
		if not open
			continue

		try
			unlock = await filelock port
			if unlock
				return { port, unlock }

		catch error
			continue

	throw new Error 'No port found'
