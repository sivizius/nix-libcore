{ context, debug, intrinsics, list, string, time, type, ... }:
let
  debug'                                =   debug ( context ++ [ "version" ] );

  Version# { major: string, minor: string, patch: string } -> Version
  =   { major, minor, patch }:
      {
        __type__                        =   "Version";
        inherit major minor patch;
      };
in
{
  compare#: string -> string -> int
  =   intrinsics.compareVersions
  or  (
        debug'.unimplemented "compare"
      ); /* maybe with string? */

  deriveVersion#: ?
  =   dateTime:
        let
          dateTime'                     =   time dateTime;
        in
          if dateTime' != null
            then
              "${dateTime'.year}-${dateTime'.month}-${dateTime'.day}"
            else
              "dev";

  language#: string?
  =   intrinsics.langVersion or null;

  main#: string -> string
  =   version: "${string version.major}.${string version.minor}";

  nix#: string?
  =   intrinsics.nixVersion or null;

  parseDerivationName#: string -> { name: string, version: string }
  =   intrinsics.parseDrvName
  or  (
        derivationName:
          let
            result                      =   string.match "(([^-]|-[^0-9])*)-([0-9].*)" derivationName;
          in
            {
              name                      =   list.get result 0;
              version                   =   list.get result 2;
            }
      );

  split#: string -> Version
  =   version:
        let
          result                        =   string.split "[.]" version;
        in
          Version
          {
            major                       =   list.get result 0;
            minor                       =   list.get result 1;
            patch                       =   list.get result 2;
          };

  split'#: string -> [ string ]
  =   intrinsics.splitVersion
  or  (
        version:
          string.splitAt "[.]" version
      );
}
