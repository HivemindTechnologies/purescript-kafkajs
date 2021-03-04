

exports.makeConsumerImpl = (kafka, consumerConfig) => kafka.consumer(consumerConfig)

exports.connectImpl = (consumer) => () => consumer.connect()

exports.subscribeImpl = (consumer, subscriptionConfig) => () => consumer.subscribe(subscriptionConfig)

exports.eachBatchImpl = (consumer, eachBatchAutoResolve, handler) => () => {
    return consumer.run({
        eachBatchAutoResolve: eachBatchAutoResolve,
        eachBatch:  ({ batch, resolveOffset, heartbeat, isRunning, isStale }) => {
            const resolveOffsetEff = offset => () => resolveOffset(offset)
            
            return handler(batch,resolveOffsetEff,heartbeat,isRunning,isStale)()
            // console.log(batch)
            // for (let message of batch.messages) {
            //     resolveOffset(message.offset)
            // }
        }
    })
}
