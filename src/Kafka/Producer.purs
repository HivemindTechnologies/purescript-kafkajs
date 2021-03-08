module Kafka.Producer
  ( Producer
  , ProducerConfig
  , makeProducer
  , connect
  , ProducerMessage
  , ProducerBatch
  , InternalProducerMessage
  , InternalProducerBatch
  , toInternalProducerMessage
  , toInternalProducerBatch
  , RecordMetadata
  , send
  , disconnect
  ) where

import Prelude (Unit, (#), (>>>), (<#>))
import Control.Promise (Promise, toAffE)
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toNullable)
import Effect (Effect)
import Effect.Aff (Aff)
import Kafka.Kafka (Kafka)
import Kafka.Types (Partition(..), Topic(..))
import Data.Newtype (un)

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
    , maxInFlightRequests: toNullable pc.maxInFlightRequests
    }

foreign import connectImpl :: Producer -> Effect (Promise Unit)

connect :: Producer -> Aff Unit
connect = connectImpl >>> toAffE

type ProducerMessage
  = { key :: Maybe String
    , value :: String
    , partition :: Maybe Partition
    }

type ProducerBatch
  = { topic :: Topic
    , messages :: Array (ProducerMessage)
    }

foreign import data RecordMetadata :: Type

type InternalProducerMessage
  = { key :: Nullable String
    , value :: String
    , partition :: Nullable Int
    }

type InternalProducerBatch
  = { topic :: String
    , messages :: Array (InternalProducerMessage)
    }

toInternalProducerMessage :: ProducerMessage -> InternalProducerMessage
toInternalProducerMessage { key, value, partition: partition } = { key: toNullable key, value: value, partition: partition <#> un Partition # toNullable }

toInternalProducerBatch :: ProducerBatch -> InternalProducerBatch
toInternalProducerBatch { topic: Topic topic, messages } = { topic, messages: messages <#> toInternalProducerMessage }

foreign import sendImpl :: Fn2 Producer InternalProducerBatch (Effect (Promise (Array RecordMetadata)))

send :: Producer -> ProducerBatch -> Aff (Array RecordMetadata)
send p pl = runFn2 sendImpl p (toInternalProducerBatch pl) # toAffE

foreign import disconnectImpl :: Producer -> Effect (Promise Unit)

disconnect :: Producer -> Aff Unit
disconnect = disconnectImpl >>> toAffE
