
import lockfile		from 'proper-lockfile'
import ensureFile 	from './ensure-file'

export default (name, timeout = 1000 * 60 * 5) ->

	# ---------------------------------------------------------
	# First make sure the path is writeable

	lockPath = "/var/tmp/dynamodb-offline-server-#{name}"
	# console.log lockPath
	await ensureFile lockPath

	# ---------------------------------------------------------
	# Acquire the lock

	unlock = await lockfile.lock lockPath, {
		stale: timeout
		retries:
			retries: 0
	}

	return unlock
