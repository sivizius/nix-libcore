{
  description                           =   "Core library of general-purpose expressions worth implementing as intrinsics";
  inputs
  =   {
        intrinsics.url                  =   "/home/sivizius/Projects/Active/nixfiles/intrinsics";
      };
  outputs
  =   { intrinsics, ... }:
        import ./.
        {
          context                       =   [ "libcore" ];
          intrinsics                    =   intrinsics.lib;
        };
}