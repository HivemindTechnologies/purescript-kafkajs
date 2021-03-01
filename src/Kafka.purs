module Kafka
  ( SaslConfig
  , Kafka
  , Producer
  , Transaction
  , RecordMetadata
  , KafkaConfig
  , ProducerConfig
  , makeClient
  , makeProducer
  , connect
  , Message
  , Payload
  , send
  , sendT
  , abort
  , commit
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

type Message
  = { key :: Maybe String
    , value :: String
    , partition :: Maybe Int
    }

type Payload
  = { topic :: String
    , messages :: Array (Message)
    }

type InternalMessage
  = { key :: Nullable String
    , value :: String
    , partition :: Nullable Int
    }

type InternalPayload
  = { topic :: String
    , messages :: Array (InternalMessage)
    }

foreign import data RecordMetadata :: Type

foreign import sendImpl :: Fn2 Producer InternalPayload (Effect (Promise (Array RecordMetadata)))

foreign import sendTImpl :: Fn2 Transaction InternalPayload (Effect (Promise (Array RecordMetadata)))

convertMessage :: Message -> InternalMessage
convertMessage { key, value, partition } = { key: toNullable key, value: value, partition: toNullable partition }

convert :: Payload -> InternalPayload
convert { topic, messages } = { topic, messages: messages <#> convertMessage }


send :: Producer -> Payload -> Aff (Array RecordMetadata)
send p pl = runFn2 sendImpl p (convert pl) # toAffE

sendT :: Transaction -> Payload -> Aff (Array RecordMetadata)
sendT t pl = runFn2 sendTImpl t (convert pl) # toAffE

foreign import disconnectImpl :: Producer -> Effect (Promise Unit)

disconnect :: Producer -> Aff Unit
disconnect = disconnectImpl >>> toAffE
