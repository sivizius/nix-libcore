{
  description                           =   "Core library of general-purpose expressions worth implementing as intrinsics";
  inputs
  =   {
        intrinsics.url                  =   "github:sivizius/nix-intrinsics/master";
      };
  outputs
  =   { intrinsics, ... }:
        import ./.
        {
          context                       =   [ "libcore" ];
          intrinsics                    =   intrinsics.lib;
        };
}