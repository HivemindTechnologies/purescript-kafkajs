module Test.Main where

import Data.Unit (Unit)
import Effect (Effect)
import Effect.Class.Console (log)

main :: Effect Unit 
main = 
    do
      log "Add some tests"