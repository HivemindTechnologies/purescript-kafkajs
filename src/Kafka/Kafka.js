const { Kafka } = require('kafkajs')

exports.makeClientImpl = params => new Kafka(params)
