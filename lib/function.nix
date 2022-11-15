{ context, debug, intrinsics, ... }:
let
  debug'                                =   debug ( context ++ [ "function" ] );

  arguments#: F -> { bool... }
  # where
  #   F: { ... } -> T,
  #   T: Any
  =   intrinsics.functionArgs
  or  (
        function:
          debug'.unimplemented "arguments"
      );

  fixPointOf#: F -> T
  # where
  #   F: T -> T
  =   function:
        let
          fixPoint                      =   function fixPoint;
        in
          fixPoint;

  identity#: T -> T
  =   _: _;
in
{
  fix                                   =   fixPointOf;
  id                                    =   identity;
  inherit arguments fixPointOf;
}