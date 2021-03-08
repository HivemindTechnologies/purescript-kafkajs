module Kafka.Types
  ( Offset(..)
  , Partition(..)
  , Topic(..)
  ) where

import Data.Newtype (class Newtype)
import Data.Show (class Show)

newtype Offset
  = Offset Int

instance ntOffset :: Newtype Offset Int

derive newtype instance showOffset :: Show Offset

newtype Partition
  = Partition Int

instance ntPartiton :: Newtype Partition Int

derive newtype instance showPartition :: Show Partition

newtype Topic
  = Topic String

instance ntTopic :: Newtype Topic String

derive newtype instance showTopic :: Show Topic
