{ intrinsics, ... }:
let
  inherit(intrinsics) attrNames foldl' mapAttrs scopedImport typeOf;

  module
  =   __path__:
      {
        inherit __path__;
        __module__                      =   scopedImport { inherit module; } __path__;
      };

  isModule                              =   this: typeOf this == "set" && this ? __module__;

  create                                =   extend {};

  extend
  =   { ... } @ initialLib:
      { ... } @ lib:
      (
        /*mapAttrs
        (
          name:
          value:
            if isModule value
            then
              #__trace "!!!"
              #traceDeep value
              ( value.__module__ { foo = 1; } )
            else
              #__trace "???"
              #traceDeep value
              value
        )*/
        (
          foldl'
          (
            result:
            moduleName:
              let
                value                   =   lib.${moduleName};
                # Some fix-point magic.
                value'                  =   value.__module__ (extend initialLib lib);
              in
                result
                //  {
                      ${moduleName}
                      =   if isModule value
                          then
                            #__trace value.__path__
                            value'
                          else
                            value;
                    }

          )
          initialLib
          ( attrNames lib )
        )
      );
in
{
  inherit create extend module;
}
