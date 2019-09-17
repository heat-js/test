
import lockfile		from 'proper-lockfile'
import ensureFile 	from './ensure-file.coffee'

export default (timeout = 5000) ->

	# ---------------------------------------------------------
	# First make sure the path is writeable

	lockPath = "/var/tmp/dynamodb-offline-server"
	await ensureFile lockPath

	# ---------------------------------------------------------
	# Acquire the lock

	unlock = await lockfile.lock lockPath, {
		stale: timeout
		retries:
			retries: 	Math.floor timeout / 1000
			factor: 	1
			minTimeout: 1000
			maxTimeout: timeout
			randomize: 	true
	}

	return unlock
