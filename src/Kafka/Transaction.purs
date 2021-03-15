module Kafka.Transaction
  ( Transaction
  , transaction
  , commit
  , abort
  , send
  , sendOffsets
  , SendOffsets
  , TopicCommit
  , PartitionCommit
  ) where

import Control.Promise (Promise, toAffE)
import Data.Function.Uncurried (Fn2, runFn2)
import Effect (Effect)
import Effect.Aff (Aff)
import Kafka.Consumer (GroupId)
import Kafka.Producer (InternalProducerBatch, Producer, ProducerBatch, RecordMetadata, toInternalProducerBatch)
import Kafka.Types (Offset, Partition, Topic)
import Prelude (Unit, (#), (>>>))

foreign import data Transaction :: Type

foreign import transactionImpl :: Producer -> Effect (Promise Transaction)

transaction :: Producer -> Aff Transaction
transaction = transactionImpl >>> toAffE

type PartitionCommit = {
    partition:: Partition,
    offset :: Offset
  }

type TopicCommit = {
  topic :: Topic,
  partitions :: Array PartitionCommit
}

type SendOffsets = {
  consumerGroupId :: GroupId,
  topics :: Array TopicCommit
}

foreign import sendOffsetsImpl :: Fn2 Transaction SendOffsets (Effect (Promise Unit))

sendOffsets :: Transaction -> SendOffsets -> Aff Unit  
sendOffsets t so = runFn2 sendOffsetsImpl t so # toAffE

foreign import sendImpl :: Fn2 Transaction InternalProducerBatch (Effect (Promise (Array RecordMetadata)))

send :: Transaction -> ProducerBatch -> Aff (Array RecordMetadata)
send t pl = runFn2 sendImpl t (toInternalProducerBatch pl) # toAffE

foreign import commitImpl :: Transaction -> Effect (Promise Unit)

commit :: Transaction -> Aff Unit
commit = commitImpl >>> toAffE

foreign import abortImpl :: Transaction -> Effect (Promise Unit)

abort :: Transaction -> Aff Unit
abort = abortImpl >>> toAffE

