{ ... } @ libs:
  let
    lib                                 =   import ./lib libs;
  in
  {
    inherit lib;
    checks
    =   lib.list.fold
        (
          { ... } @ result:
          system:
            result
            //  {
                  ${system}.default     =   lib.check system lib.tests {};
                }
        )
        {}
        [ "x86_64-linux" ];
  }