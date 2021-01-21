module Kafka (
  SaslConfig
, Kafka
, Producer
, RecordMetadata
, KafkaConfig
, ProducerConfig
, makeClient
, makeProducer
, connect
, Message 
, Payload
, send
, disconnect
) where

import Prelude
import Control.Promise (Promise, toAffE)
import Data.Function.Uncurried (Fn2, runFn2)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toNullable)
import Effect (Effect)
import Effect.Aff (Aff)

foreign import data Kafka :: Type

type SaslConfig
  = { mechanism :: String
    , username :: String
    , password :: String
    }

type InternalKafkaConfig
  = { clientId :: String
    , brokers :: Array String
    , ssl :: Boolean
    , sasl :: Nullable SaslConfig
    }

type KafkaConfig
  = { clientId :: String
    , brokers :: Array String
    , ssl :: Boolean
    , sasl :: Maybe SaslConfig
    }

foreign import data Producer :: Type

type ProducerConfig
  = {}

foreign import makeClientImpl :: InternalKafkaConfig -> Kafka

makeClient :: KafkaConfig -> Kafka
makeClient = toInternal >>> makeClientImpl
  where
  toInternal config =
    { clientId: config.clientId
    , brokers: config.brokers
    , ssl: config.ssl
    , sasl: toNullable config.sasl
    }

foreign import makeProducerImpl :: Fn2 Kafka ProducerConfig Producer

makeProducer :: Kafka -> ProducerConfig -> Producer
makeProducer = runFn2 makeProducerImpl

foreign import connectImpl :: Producer -> Effect (Promise Unit)

connect :: Producer -> Aff Unit
connect = connectImpl >>> toAffE

type Message
  = { value :: String }

type Payload
  = { topic :: String
    , messages :: Array (Message)
    }

foreign import data RecordMetadata :: Type

foreign import sendImpl :: Fn2 Producer Payload (Effect (Promise (Array RecordMetadata)))

send :: Producer -> Payload -> Aff (Array RecordMetadata)
send p pl = runFn2 sendImpl p pl # toAffE

foreign import disconnectImpl :: Producer -> Effect (Promise Unit)

disconnect :: Producer -> Aff Unit
disconnect = disconnectImpl >>> toAffE
