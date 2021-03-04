module Kafka.Example.Producer where

import Prelude (Unit, (>>>), (#), (<#>), bind, ($), (<>), pure, unit, (*>), (+))
import Control.Promise (Promise, toAffE, fromAff)
import Effect (Effect)
import Kafka.Producer (connect, disconnect, Producer, makeProducer, ProducerConfig)
import Kafka.Kafka
import Kafka.Transaction (transaction, send, commit, abort)
import Data.Maybe (Maybe(..))
import Effect.Aff (bracket, delay, Aff)
import Data.Show (show)
import Data.Traversable (for)
import Effect.Class.Console (log)
import Data.Time.Duration (Milliseconds(..))
import Effect.Random (randomBool)
import Effect.Class (liftEffect)

-- | Send 10 messages every 5 seconds and randomly abort or commit
use :: Int -> Producer -> Aff Unit
use run producer = do
  trx <- transaction producer
  condition <- liftEffect $ randomBool
  _ <-
    send trx
      { topic: "transactions"
      , messages:
          [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
            <#> \i ->
                { key: Nothing
                , value: "[run=" <> (show run) <> ", msg=" <> (show i) <> ", committed=" <> (show condition) <> "]"
                , partition: Nothing
                }
      }
  _ <-
    if condition then
      commit trx *> (log $ "Run " <> (show run) <> " was committed.")
    else
      abort trx *> (log $ "Run " <> (show run) <> " was aborted.")
  delay (Milliseconds 5000.0) *> use (run + 1) producer

main :: Effect (Promise Unit)
main =
  fromAff
    $ do
        let
          kafka = makeClient { clientId: "transactional-producer", brokers: [ "localhost:9092" ], ssl: false, sasl: Nothing }

          producerConfig = { idempotent: Just true, transactionalId: Just "tx-0", maxInFlightRequests: Nothing }

          acquire :: Kafka -> ProducerConfig -> Aff Producer
          acquire kafka conf = makeProducer kafka conf # \producer -> connect producer *> pure producer

          release :: Producer -> Aff Unit
          release = disconnect
        _ <- bracket (acquire kafka producerConfig) release (use 0)
        pure unit
