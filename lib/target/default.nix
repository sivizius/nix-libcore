{ context,... } @ libs:
let
  libs'
  =   libs
  //  {
        context                         =   context ++ [ "target" ];
        inherit Architecture Kernel System;
      };

  Architecture                          =   import ./architecture.nix libs';
  Kernel                                =   import ./kernel.nix       libs';
  System                                =   import ./system.nix       libs';
in
{
  inherit Architecture Kernel System;
}
