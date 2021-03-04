module Kafka.Consumer where

import Prelude (Unit, (>>>), (#), (<#>), bind, ($), (<>))
import Control.Promise (Promise, toAffE, fromAff)
import Kafka.Kafka (Kafka)
import Data.Function.Uncurried (Fn2, Fn3, Fn7, mkFn7, runFn2, runFn3)
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Aff (Aff)
import Kafka.Internal.Internal (InternalOutputMessage)
import Kafka.Types
import Data.Nullable (Nullable, toNullable, toMaybe)
import Node.Buffer (Buffer)
import Data.Maybe (Maybe(..), maybe)
import Data.Traversable (traverse)
import Node.Buffer (toString)
import Node.Encoding (Encoding(..))
import Control.Monad.Error.Class (class MonadThrow, throwError)
import Effect.Exception (error, Error)
import Data.Int (fromString)
import Control.Applicative (pure)
import Data.Either (Either(..), note, either)
import Data.Newtype (un)

foreign import data Consumer :: Type

type ConsumerConfig
  = { groupId :: String
    , readUncommitted :: Boolean
    , autoCommit :: Boolean
    }

type SubscriptionConfig
  = { topic :: String }

foreign import makeConsumerImpl :: Fn2 Kafka ConsumerConfig Consumer

makeConsumer :: Kafka -> ConsumerConfig -> Consumer
makeConsumer = runFn2 makeConsumerImpl

foreign import connectImpl :: Consumer -> Effect (Promise Unit)

connect :: Consumer -> Aff Unit
connect = connectImpl >>> toAffE

foreign import subscribeImpl :: Fn2 Consumer SubscriptionConfig (Effect (Promise Unit))

subscribe :: Consumer -> SubscriptionConfig -> Aff Unit
subscribe consumer subscriptionConfig = runFn2 subscribeImpl consumer subscriptionConfig # toAffE

type InternalConsumerMessage
  = { key :: Nullable Buffer
    , value :: Buffer
    , offset :: String
    }

type InternalConsumerBatch
  = { fetchedOffset :: String
    , highWatermark :: String
    , messages :: Array InternalConsumerMessage
    , partition :: Int
    , topic :: String
    }

type ConsumerMessage
  = { key :: Maybe Buffer
    , value :: Buffer
    , offset :: Offset
    }

type ConsumerBatch
  = { fetchedOffset :: Offset
    , highWatermark :: Offset
    , messages :: Array ConsumerMessage
    , partition :: Partition
    , topic :: Topic
    }

type InternalHeartbeat
  = Effect (Promise Unit)

type Heartbeat
  = Aff Unit

type InternalResolveOffset
  = Int -> Effect Unit

type ResolveOffset
  = Offset -> Effect Unit

type InternalCommitOffsetsIfNecessary
  = Effect (Promise Unit)

type CommitOffsetsIfNecessary
  = Aff Unit

type InternalOffsetInfo
  = { topics ::
        Array
          { partitions ::
              Array
                { offset :: String
                , partition :: String
                }
          , topic :: String
          }
    }

type InternalUncommittedOffsets
  = Effect InternalOffsetInfo

type OffsetInfo
  = { topics ::
        Array
          { partitions ::
              Array
                { offset :: Offset
                , partition :: Partition
                }
          , topic :: Topic
          }
    }

raiseMaybe :: forall a. Maybe a -> Effect a
raiseMaybe = maybe (throwError $ error "Maybe is Nothing") pure

raiseEither :: forall a. Either String a -> Effect a
raiseEither = either (error >>> throwError) pure

toOffsetInfo :: InternalOffsetInfo -> Effect OffsetInfo
toOffsetInfo { topics } = do
  topicInfo <- traverse parseTopicInfo topics
  pure { topics: topicInfo }
  where
  parsePartitionInfo ::
    { offset :: String
    , partition :: String
    } ->
    Effect
      { offset :: Offset
      , partition :: Partition
      }
  parsePartitionInfo { offset, partition } = do
    o <- raiseMaybe $ fromString offset
    p <- raiseMaybe $ fromString partition
    pure { offset: Offset o, partition: Partition p }

  parseTopicInfo ::
    { partitions ::
        Array
          { offset :: String
          , partition :: String
          }
    , topic :: String
    } ->
    Effect
      { partitions ::
          Array
            { offset :: Offset
            , partition :: Partition
            }
      , topic :: Topic
      }
  parseTopicInfo { partitions, topic } = do
    partitionInfo <- traverse parsePartitionInfo partitions
    pure { partitions: partitionInfo, topic: Topic topic }

type UncommittedOffsets
  = Effect OffsetInfo

type InternalIsStale
  = Effect Boolean

type IsStale
  = Effect Boolean

type InternalIsRunning
  = Effect Boolean

type IsRunning
  = Effect Boolean

type EachBatchImpl
  = Fn7
      InternalConsumerBatch
      InternalResolveOffset
      InternalHeartbeat
      InternalCommitOffsetsIfNecessary
      InternalUncommittedOffsets
      InternalIsRunning
      InternalIsStale
      (Effect (Promise Unit))

type EachBatch
  = ConsumerBatch ->
    ResolveOffset ->
    Heartbeat ->
    CommitOffsetsIfNecessary ->
    UncommittedOffsets ->
    IsRunning ->
    IsStale ->
    (Aff Unit)

toConsumerMessage :: InternalConsumerMessage -> Either String ConsumerMessage
toConsumerMessage { key, value, offset } = do
  o <- note "offset is not a number" $ fromString offset
  pure
    { key: toMaybe key
    , value: value
    , offset: Offset o
    }

toConsumerBatch :: InternalConsumerBatch -> Either String ConsumerBatch
toConsumerBatch { fetchedOffset, highWatermark, messages, partition, topic } = do
  fo <- note "fetchedOffset is not a number" $ fromString fetchedOffset
  hwm <- note "highWatermark is not a number" $ fromString highWatermark
  msgs <- traverse toConsumerMessage messages
  pure
    { fetchedOffset: Offset fo
    , highWatermark: Offset hwm
    , messages: msgs
    , partition: Partition partition
    , topic: Topic topic
    }

foreign import eachBatchImpl :: Fn3 Consumer Boolean EachBatchImpl (Effect (Promise Unit))

eachBatch :: Consumer -> Boolean -> EachBatch -> Aff Unit
eachBatch consumer eachBatchAutoResolve handler =
  let
    iResolveOffset :: (Int -> Effect Unit) -> (Offset -> Effect Unit)
    iResolveOffset f = un Offset >>> f

    iUncommitedOffsets :: Effect InternalOffsetInfo -> Effect OffsetInfo
    iUncommitedOffsets ioiEff = do
      ioi <- ioiEff
      toOffsetInfo ioi

    internalHandlerCurried ::
      InternalConsumerBatch ->
      InternalResolveOffset ->
      InternalHeartbeat ->
      InternalCommitOffsetsIfNecessary ->
      InternalUncommittedOffsets ->
      InternalIsRunning ->
      InternalIsStale ->
      (Effect (Promise Unit))
    internalHandlerCurried icb iro ih icoin iuo iir iis = do
      batch <- raiseEither (toConsumerBatch icb)
      handler
        batch
        (iResolveOffset iro)
        (toAffE ih)
        (toAffE icoin)
        (iUncommitedOffsets iuo)
        (iir)
        (iis)
        # fromAff

    internalHandler :: EachBatchImpl
    internalHandler = mkFn7 internalHandlerCurried
  in
    runFn3 eachBatchImpl consumer eachBatchAutoResolve internalHandler # toAffE

foreign import disconnectImpl :: Consumer -> Effect (Promise Unit)

disconnect :: Consumer -> Aff Unit
disconnect = disconnectImpl >>> toAffE