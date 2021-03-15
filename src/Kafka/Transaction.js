

exports.transactionImpl = (producer) => () => producer.transaction()

exports.sendImpl = (transaction, data) => () => transaction.send(data)

exports.sendOffsetsImpl = (transaction, sendOffsets) => () => transaction.sendOffsets(sendOffsets)

exports.commitImpl = (transaction) => () => transaction.commit()

exports.abortImpl = (transaction) => () => transaction.abort()
