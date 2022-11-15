{ intrinsics, type, ... }:
let
  inherit(type) never;
in
{
  derivation
  =   intrinsics.derivation
  or  (
        { name, builder, system, ... } @ drvAttrs:
        {
          inherit name drvAttrs;
          all                           =   never; # ToDo!
          builder                       =   builder; # ToDo: Check!
          drvPath                       =   never; # ToDo!
          out                           =   never; # ToDo!
          outPath                       =   never; # ToDo!
          outputName                    =   "out";
          system                        =   system; # ToDo: Check!
          type                          =   "derivation";
        }
      );
}