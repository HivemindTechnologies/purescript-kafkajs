const { Kafka } = require('kafkajs')

exports.makeClientImpl = params => new Kafka(params)

exports.makeProducerImpl = (kafka, producerConfig) => kafka.producer(producerConfig)

exports.connectImpl = (producer) => () => producer.connect()

exports.sendImpl = (producer, data) => () => producer.send(data)

exports.disconnectImpl = (producer) => () => producer.disconnect()
