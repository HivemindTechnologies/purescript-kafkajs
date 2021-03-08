{ name = "kafkajs"
, dependencies =
  [ "aff-promise"
  , "console"
  , "debug"
  , "effect"
  , "maybe"
  , "node-buffer"
  , "nullable"
  , "psci-support"
  , "spec"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
, license = "MIT"
, repository = "https://github.com/HivemindTechnologies/purescript-kafkajs.git"
}
