{
  checked     ? false,    # enable e.g. type-checks
  context     ? [],       # Debugging-Context
  intrinsics  ? builtins, # intrinsic/builtin functions, variables, etc.
  ...
}:
let
  inherit (import ./library.nix { inherit intrinsics; }) create module;
in
  create
  {
    inherit context checked;
    intrinsics
    =   (
          {
            # necessary!
            abort, attrNames, bitAnd, bitOr, bitXor, deepSeq, elemAt, fetchurl, filterSource, functionArgs, import,
            length, match, path, pathExists, placeholder, readDir, readFile, scopedImport, seq, split, storePath,
            substring, throw, toFile, toString, tryEval, typeOf,

            # maybe possible to construct?
            fetchGit, toJSON, fetchTarball, toXML,

            ...
          } @ x: x
        ) intrinsics;
    bool                                =   module ./bool.nix;
    debug                               =   module ./debug.nix;
    dictionary                          =   module ./set.nix;
    environment                         =   module ./environment.nix;
    error                               =   module ./error.nix;
    expression                          =   module ./expression.nix;
    flake                               =   module ./flake.nix;
    float                               =   module ./float.nix;
    function                            =   module ./function.nix;
    indentation                         =   module ./indentation.nix;
    integer                             =   module ./integer.nix;
    library                             =   module ./library.nix;
    list                                =   module ./list;
    null                                =   module ./null.nix;
    number                              =   module ./number.nix;
    path                                =   module ./path.nix;
    set                                 =   module ./set.nix;
    string                              =   module ./string;
    target                              =   module ./target;
    time                                =   module ./time.nix;
    type                                =   module ./type;
    version                             =   module ./version.nix;
  }
