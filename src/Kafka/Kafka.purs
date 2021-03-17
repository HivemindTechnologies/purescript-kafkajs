module Kafka.Kafka
  ( SaslConfig
  , Kafka
  , KafkaConfig
  , makeClient
  , LogLevel(..)
  ) where

import Prelude
import Data.Maybe (Maybe)
import Data.Nullable (Nullable, toNullable)

foreign import data Kafka :: Type


data LogLevel = LogNothing | LogDebug | LogInfo | LogWarn | LogError

foreign import data InternalLogLevel :: Type

foreign import internalLogNothing :: InternalLogLevel

foreign import internalLogDebug :: InternalLogLevel
foreign import internalLogInfo:: InternalLogLevel
foreign import internalLogWarn :: InternalLogLevel
foreign import internalLogError :: InternalLogLevel

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
    , logLevel :: Nullable InternalLogLevel
    }

type KafkaConfig
  = { clientId :: String
    , brokers :: Array String
    , ssl :: Boolean
    , sasl :: Maybe SaslConfig
    , logLevel :: Maybe LogLevel 
    }

foreign import makeClientImpl :: InternalKafkaConfig -> Kafka

makeClient :: KafkaConfig -> Kafka
makeClient = toInternal >>> makeClientImpl
  where

  toInternalLogLevel LogNothing = internalLogNothing
  toInternalLogLevel LogDebug = internalLogDebug
  toInternalLogLevel LogInfo = internalLogDebug
  toInternalLogLevel LogWarn = internalLogWarn
  toInternalLogLevel LogError = internalLogError

  toInternal config =
    { clientId: config.clientId
    , brokers: config.brokers
    , ssl: config.ssl
    , sasl: toNullable config.sasl
    , logLevel : config.logLevel <#> toInternalLogLevel # toNullable
    }
