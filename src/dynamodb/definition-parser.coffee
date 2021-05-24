
# import fs							from 'fs'
# import YAML							from 'js-yaml'
# import { CLOUDFORMATION_SCHEMA }	from 'js-yaml-cloudformation-schema'

# export default class DefinitionParser

# 	parseFiles: (path) ->
# 		paths = [ path ].flat()
# 		paths = paths.flat()

# 		tables = paths.map (path) => @parseFile path
# 		tables = tables.flat()

# 		return tables

# 	parseFile: (path) ->
# 		yaml      = fs.readFileSync path
# 		resources = YAML.load yaml, {
# 			schema: CLOUDFORMATION_SCHEMA
# 		}

# 		return @parse resources

# 	parse: (path) ->
# 		definitions = []
# 		for name, resource of resources
# 			if resource.Type isnt 'AWS::DynamoDB::Table'
# 				continue

# 			properties = Object.assign {}, resource.Properties

# 			properties.BillingMode = 'PAY_PER_REQUEST'

# 			delete properties.TimeToLiveSpecification
# 			delete properties.PointInTimeRecoverySpecification
# 			delete properties.Tags

# 			if properties.StreamSpecification
# 				properties.StreamSpecification.StreamEnabled = true

# 			definitions.push properties

# 		return definitions



import { load } from '@heat/awsless'

export default class DefinitionParser

	parse: (path) ->
		stacks = await load path, {
			resolveRemoteResolvers: false
			resolveLocalResolvers: false
		}
		resources = {}
		for stack in stacks
			template = JSON.parse stack.templateBody
			Object.assign resources, template.Resources

		definitions = []
		for name, resource of resources
			if resource.Type isnt 'AWS::DynamoDB::Table'
				continue

			properties = Object.assign {}, resource.Properties

			properties.BillingMode = 'PAY_PER_REQUEST'

			delete properties.TimeToLiveSpecification
			delete properties.PointInTimeRecoverySpecification
			delete properties.Tags

			if properties.StreamSpecification
				properties.StreamSpecification.StreamEnabled = true

			definitions.push properties

		return definitions
