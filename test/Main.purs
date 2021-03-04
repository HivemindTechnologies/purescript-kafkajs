module Test.Main where

import Prelude
import Effect (Effect)
import Effect.Class (liftEffect)
import Prelude (Unit, bind, ($))
import Test.Spec (Spec, describe, pending')
import Test.Spec.Assertions (shouldEqual)
import Kafka.Kafka (makeClient)
import Kafka.Consumer
import Kafka.Internal.Internal (InternalOutputMessage)
import Data.Maybe (Maybe(..))
import Data.Traversable (for, traverse)
import Effect.Class.Console (log)
import Effect.Aff (Aff)
import Control.Promise (Promise, fromAff)
import Data.Show (show)
import Debug.Trace (spy)
import Node.Buffer (toString)
import Node.Encoding (Encoding(..))

f :: ResolveOffset -> InternalOutputMessage -> Aff Unit
f resolveOffset m = do
  value <- liftEffect $ toString UTF8 m.value
  let _ = spy "d" value
  liftEffect $ resolveOffset (m.offset)

main :: Effect (Promise Unit)
main =
  fromAff
    $ do
        let
          kafka = makeClient { clientId: "hans", brokers: [ "localhost:9092" ], ssl: false, sasl: Nothing }

          consumer = makeConsumer kafka { groupId: "wurstf" }

          handler :: EachBatch
          handler { messages } resolveOffset _ _ _ _ _ = do
            _ <- traverse (f resolveOffset) messages :: Aff (Array Unit)
            pure unit
        connect consumer
        subscribe consumer { topic: "bratwurst" }
        eachBatch consumer false handler
        true `shouldEqual` true
