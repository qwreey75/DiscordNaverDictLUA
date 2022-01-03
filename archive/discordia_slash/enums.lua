local enum = require('discordia').enums.enum

return {
	optionType = enum({
		subCommand = 1,
		subCommandGroup = 2,
		string = 3,
		integer = 4,
		boolean = 5,
		user = 6,
		channel = 7,
		role = 8
	}),
	applicationCommandPermissionType = enum({
		role = 1,
		user = 2,
	})
}