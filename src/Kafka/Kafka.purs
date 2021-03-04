module Kafka.Kafka
  ( SaslConfig
  , Kafka
  , RecordMetadata
  , KafkaConfig
  , makeClient
  , Message
  , Payload
  ) where

import Prelude
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toNullable)

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


type Message
  = { key :: Maybe String
    , value :: String
    , partition :: Maybe Int
    }

type Payload
  = { topic :: String
    , messages :: Array (Message)
    }


foreign import data RecordMetadata :: Type



