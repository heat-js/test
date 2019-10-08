
import fs	from 'fs'
import util	from 'util'

exists 	= util.promisify fs.exists
open 	= util.promisify fs.open
close 	= util.promisify fs.close

export default (path) ->
	if not await exists path
		file = await open path, 'w'
		await close file
