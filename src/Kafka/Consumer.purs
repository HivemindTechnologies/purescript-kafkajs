module Kafka.Consumer where

import Prelude (Unit, (>>>), (#))
import Control.Promise (Promise, toAffE, fromAff)
import Kafka.Kafka (Kafka)
import Data.Function.Uncurried (Fn2, Fn3, Fn7, mkFn7, runFn2, runFn3)
import Effect (Effect)
import Effect.Aff (Aff)
import Kafka.Internal.Internal (InternalOutputMessage)

foreign import data Consumer :: Type

type ConsumerConfig
  = { groupId :: String }

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

type Offset
  = Int

type Batch
  = { fetchedOffset :: String
    , highWatermark :: String
    , messages :: Array InternalOutputMessage
    , partition :: Int
    , topic :: String
    }

type Heartbeat
  = Aff Unit

type ResolveOffset
  = Offset -> Effect Unit

type CommitOffsetsIfNecessary
  = Aff Unit

type UncommittedOffsets
  = Aff (Array Offset)

type IsStale
  = Aff Boolean

type IsRunning
  = Aff Boolean

type EachBatchImpl
  = Fn7
      Batch
      ResolveOffset
      Heartbeat
      CommitOffsetsIfNecessary
      UncommittedOffsets
      IsRunning
      IsStale
      (Effect (Promise Unit))

type EachBatch
  = Batch ->
    ResolveOffset ->
    Heartbeat ->
    CommitOffsetsIfNecessary ->
    UncommittedOffsets ->
    IsRunning ->
    IsStale ->
    (Aff Unit)

foreign import eachBatchImpl :: Fn3 Consumer Boolean EachBatchImpl (Effect (Promise Unit))

eachBatch :: Consumer -> Boolean -> EachBatch -> Aff Unit
eachBatch consumer eachBatchAutoResolve handler =
  let
    promised b r h c u ir is = handler b r h c u ir is # fromAff

    handlerImpl = mkFn7 promised
  in
    runFn3 eachBatchImpl consumer eachBatchAutoResolve handlerImpl # toAffE
