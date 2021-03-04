module Kafka.Example.Consumer where

import Prelude (Unit, (>>>), (#), (<#>), bind, ($), (<>), pure, unit, (*>), discard)
import Control.Promise (Promise, toAffE, fromAff)
import Effect (Effect)
import Effect.Console (log)
import Kafka.Consumer (connect, disconnect, Consumer, makeConsumer, ConsumerConfig, subscribe, EachBatch, eachBatch, ResolveOffset, ConsumerMessage)
import Kafka.Kafka
import Kafka.Transaction (transaction, send, commit, abort)
import Data.Maybe (Maybe(..))
import Effect.Aff (bracket, delay, Aff)
import Data.Show (show)
import Data.Traversable (for, traverse)
import Data.Time.Duration (Milliseconds(..))
import Effect.Random (randomBool)
import Effect.Class (liftEffect)
import Effect.Class.Console (logShow)
import Node.Buffer (toString)
import Node.Encoding (Encoding(..))

printAndResolve :: ResolveOffset -> ConsumerMessage -> Aff Unit
printAndResolve resolveOffset { value, offset } = do
  value <- liftEffect $ toString UTF8 value
  _ <- logShow $ "Got message: " <> value
  liftEffect $ resolveOffset offset

  

main :: Effect (Promise Unit)
main =
  fromAff
    $ do
        let
          kafka = makeClient { clientId: "transactional-consumer", brokers: [ "localhost:9092" ], ssl: false, sasl: Nothing }

          consumerConfig = { groupId: "transactional-group", readUncommitted: false, autoCommit: false } 
          
          consumer = makeConsumer kafka consumerConfig

        connect consumer 
        subscribe consumer { topic: "transactions" }
        let
          handler :: EachBatch
          handler { highWatermark, messages } resolveOffset heartBeat commitIfNecessary uncommittedOffsets isRunning isStale = do
        
            _ <- traverse (printAndResolve resolveOffset) messages :: Aff (Array Unit)
            heartBeat

        eachBatch consumer false handler
        

          