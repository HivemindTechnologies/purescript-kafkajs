module Kafka.Producer where

import Prelude (Unit, (#), (>>>))
import Control.Promise (Promise, toAffE)
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toNullable)
import Effect (Effect)
import Effect.Aff (Aff)
import Kafka.Kafka (Kafka, Payload, RecordMetadata)
import Kafka.Internal.Internal (InternalPayload, convert)

foreign import data Producer :: Type

type ProducerConfig
  = { idempotent :: Maybe Boolean
    , transactionalId :: Maybe String
    , maxInFlightRequests :: Maybe Int
    }

type InternalProducerConfig
  = { idempotent :: Nullable Boolean
    , transactionalId :: Nullable String
    , maxInFlightRequests :: Nullable Int
    }

foreign import makeProducerImpl :: Fn2 Kafka InternalProducerConfig Producer

makeProducer :: Kafka -> ProducerConfig -> Producer
makeProducer k pc = runFn2 makeProducerImpl k ipc
  where
  ipc =
    { idempotent: toNullable pc.idempotent
    , transactionalId: toNullable pc.transactionalId
    , maxInFlightRequests : toNullable pc.maxInFlightRequests
    }

foreign import connectImpl :: Producer -> Effect (Promise Unit)

connect :: Producer -> Aff Unit
connect = connectImpl >>> toAffE

foreign import sendImpl :: Fn2 Producer InternalPayload (Effect (Promise (Array RecordMetadata)))

send :: Producer -> Payload -> Aff (Array RecordMetadata)
send p pl = runFn2 sendImpl p (convert pl) # toAffE

foreign import disconnectImpl :: Producer -> Effect (Promise Unit)

disconnect :: Producer -> Aff Unit
disconnect = disconnectImpl >>> toAffE
