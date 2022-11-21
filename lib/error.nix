{ intrinsics, ... }:
let
  panic                                 =   intrinsics.throw;
in
{
  inherit panic;
  inherit (intrinsics) abort throw;
}