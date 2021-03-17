const { Kafka, logLevel } = require('kafkajs')

exports.makeClientImpl = params => new Kafka(params)

exports.internalLogNothing = logLevel.NOTHING
exports.internalLogDebug = logLevel.DEBUG
exports.internalLogInfo = logLevel.INFO
exports.internalLogWarn = logLevel.WARN
exports.internalLogError = logLevel.ERROR
