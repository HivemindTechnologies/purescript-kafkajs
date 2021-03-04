module Kafka.Internal.Internal where

import Prelude
import Kafka.Kafka (Payload, Message)
import Data.Nullable (Nullable, toNullable)
import Node.Buffer (Buffer)

type InternalMessage
  = { key :: Nullable String
    , value :: String
    , partition :: Nullable Int
    }

type InternalOutputMessage
  = { key :: Nullable String
    , value :: Buffer
    , partition :: Int
    , offset :: Int 
    }

type InternalPayload
  = { topic :: String
    , messages :: Array (InternalMessage)
    }

convertMessage :: Message -> InternalMessage
convertMessage { key, value, partition } = { key: toNullable key, value: value, partition: toNullable partition }

convert :: Payload -> InternalPayload
convert { topic, messages } = { topic, messages: messages <#> convertMessage }
