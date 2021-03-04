

exports.sendImpl = (transaction, data) => () => transaction.send(data)

exports.transactionImpl = (producer) => () => producer.transaction()

exports.commitImpl = (transaction) => () => transaction.commit()

exports.abortImpl = (transaction) => () => transaction.abort()
