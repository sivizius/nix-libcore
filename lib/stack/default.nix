{ context, ... } @ modules:
let
  unchecked                             =   import ./unchecked.nix ( modules // { context = context ++ [ "stack" ]; } );
in
  { }