
import fs							from 'fs'
import YAML							from 'js-yaml'
import { CLOUDFORMATION_SCHEMA }	from 'cloudformation-js-yaml-schema'

export default class DefinitionParser

	parseFiles: (path) ->
		paths = [ path ].flat()
		paths = paths.flat()

		tables = paths.map (path) => @parseFile path
		tables = tables.flat()

		return tables

	parseFile: (path) ->
		yaml      = fs.readFileSync path
		resources = YAML.load yaml, {
			schema: CLOUDFORMATION_SCHEMA
		}

		return @parse resources

	parse: (resources) ->
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
