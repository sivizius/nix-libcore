{ intrinsics, ... }:
let
  panic                                 =   intrinsics.abort;
in
{
  inherit panic;
  inherit (intrinsics) abort throw;
}