

exports.makeConsumerImpl = (kafka, consumerConfig) => kafka.consumer(consumerConfig)

exports.connectImpl = (consumer) => () => consumer.connect()

exports.subscribeImpl = (consumer, subscriptionConfig) => () => consumer.subscribe(subscriptionConfig)

exports.eachBatchImpl = (consumer, eachBatchAutoResolve, handler) => () => {
    return consumer.run({
        eachBatchAutoResolve: eachBatchAutoResolve,
        eachBatch: ({ 
            batch, 
            resolveOffset, 
            heartbeat,
            commitOffsetsIfNecessary, 
            uncommittedOffsets,
            isRunning, 
            isStale }) => {
            const resolveOffsetEff = offset => () => resolveOffset(offset)
            const commitOffsetsIfNecessaryEff = () => commitOffsetsIfNecessary()
            const uncommittedOffsetsEff = () => uncommittedOffsets()
            const isRunningEff = () =>  isRunning()
            const isStaleEff = () => isStale()
            
            return handler(batch, resolveOffsetEff, heartbeat, commitOffsetsIfNecessaryEff, uncommittedOffsetsEff, isRunningEff, isStaleEff)()
        }
        
    })
}

exports.disconnectImpl = (consumer) => () => consumer.disconnect()

