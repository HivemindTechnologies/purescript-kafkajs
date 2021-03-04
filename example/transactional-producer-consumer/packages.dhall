
let upstream =
      https://github.com/purescript/package-sets/releases/download/psc-0.14.0-20210307/packages.dhall sha256:5f9e009bf539a4d1fa2be3ea340aeca4e3ca69515f5e351473d722619906d0b0
  with kafkajs = ../../spago.dhall as Location
in  upstream
