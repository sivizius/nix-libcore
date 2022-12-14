{ context, ... } @ libs:
  let
    lib
    =   import ./lib
        (
          libs
          //  {
                context                 =   context ++ [ "lib" ];
              }
        );
    tests
    =   import ./tests
        (
          lib
          //  {
                context                 =   context ++ [ "tests" ];
              }
        );
    inherit(lib) check list;
  in
  {
    inherit lib tests;
    checks
    =   list.fold
        (
          { ... } @ result:
          system:
            result
            //  {
                  ${system}.default     =   check system tests {};
                }
        )
        {}
        [ "x86_64-linux" ];
  }