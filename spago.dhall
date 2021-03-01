{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "purescript-kafkajs"
, dependencies =
  [ "aff-promise", "console", "effect", "nullable", "psci-support" ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
, license = "MIT"
, repository = "https://github.com/HivemindTechnologies/purescript-kafkajs.git"
}
