module Kafka.Transaction
  ( Transaction
  , transaction
  , commit
  , abort
  , send
  ) where

import Prelude (Unit, (#), (>>>))
import Control.Promise (Promise, toAffE)
import Data.Function.Uncurried (Fn2, runFn2)
import Effect (Effect)
import Effect.Aff (Aff)
import Kafka.Producer (InternalProducerBatch, Producer, ProducerBatch, RecordMetadata, toInternalProducerBatch)

foreign import data Transaction :: Type

foreign import transactionImpl :: Producer -> Effect (Promise Transaction)

transaction :: Producer -> Aff Transaction
transaction = transactionImpl >>> toAffE

foreign import commitImpl :: Transaction -> Effect (Promise Unit)

commit :: Transaction -> Aff Unit
commit = commitImpl >>> toAffE

foreign import abortImpl :: Transaction -> Effect (Promise Unit)

abort :: Transaction -> Aff Unit
abort = abortImpl >>> toAffE

foreign import sendImpl :: Fn2 Transaction InternalProducerBatch (Effect (Promise (Array RecordMetadata)))

send :: Transaction -> ProducerBatch -> Aff (Array RecordMetadata)
send t pl = runFn2 sendImpl t (toInternalProducerBatch pl) # toAffE
