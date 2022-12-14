{ context, debug, intrinsics, list, set, string, type, ... }:
let
  debug'                                =   debug ( context ++ [ "path" ] );

  exists#: path -> bool
  =   intrinsics.pathExists
  or  (debug'.unimplemented "exists");

  fetchGit#: { ... } -> path
  =   intrinsics.fetchGit
  or  (debug'.unimplemented "fetchGit"); /* maybe with fetchURL? */

  fetchMercurial#: { ... } -> path
  =   intrinsics.fetchMercurial
  or  (debug'.unimplemented "fetchMercurial");

  fetchTarball#: { ... } -> path
  =   intrinsics.fetchTarball
  or  (debug'.unimplemented "fetchTarball"); /* maybe with fetchURL? */

  fetchURL#: string | { url: string, sha256: string } -> path
  =   intrinsics.fetchurl
  or  (debug'.unimplemented "fetchURL");

  filterSource#: (path -> string -> bool) -> path -> path
  =   intrinsics.filterSource
  or  (debug'.unimplemented "filterSource");

  from#: path | { path: path, name: string?, filter: F?, recursive: bool = true, sha256: string? } | ToString -> path
  =   this:
        if type.isPath this
        then
          this
        else if type.isSet this
        &&      this ? path
        &&      intrinsics ? path
        then
            intrinsics.path this
        else
          ./${string this};

  fromSet#: string -> (string -> T -> string) -> { string -> T } -> path
  =   fileName:
      converter:
      { ... } @ dictionary:
        toFile fileName ( string.concat ( set.values ( set.map converter dictionary ) ) );

  getBaseName#: path -> string
  =   intrinsics.baseNameOf
  or  (debug'.unimplemented "getBaseName"); /* maybe with string.match? */

  getDirectory#: path -> string
  =   intrinsics.dirOf
  or  (debug'.unimplemented "getDirectory"); /* maybe with string.match? */

  getPlaceholder#: string -> string
  =   intrinsics.placeholder
  or  (debug'.unimplemented "placeholder");

  hash#: string -> path -> string
  =   intrinsics.hashFile
  or  (
        type:
        file:
          string.hash type (readFile file)
      );

  import#: path -> any
  =   intrinsics.import;#path:
        #importWithContext path [];

  importScoped#: path -> { ... } -> any
  =   intrinsics.scopedImport
  or  (debug'.unimplemented "importScoped");

  importScoped'
  =   this:
        __trace this
        importScoped this;

  importWithContext#: path -> { ... } -> any
  =   path:
      context:
        let
          context'                      =   context ++ [ (getBaseName path) ];
        in
          __trace context
          importScoped' path
          {
            context                     =   context';
            import                      =   path: importWithContext context' path;
          };

  nixPaths#: [ { path: string, prefix: string } ]?
  =   intrinsics.nixPath or null;


  readDirectory#: path -> { string -> string }
  =   intrinsics.readDir
  or  (debug'.unimplemented "readDirectory");

  readFile#: path -> string
  =   intrinsics.readFile
  or  (debug'.unimplemented "readFile");

  storeDirectory#: string?
  =   intrinsics.storeDir or null;

  storePath#: path -> string
  =   intrinsics.storePath
  or  (debug'.unimplemented "storePath");

  toFile#: string -> string -> path
  =   intrinsics.toFile
  or  (debug'.unimplemented "toFile");

  toStore#: path -> string
  =   file:
        if type.isPath file
        then
          "${file}"
        else
          debug.panic "toStore" "Path expected!";
in
{
  __functor                             =   self: from;
  baseName                              =   debug'.deprecated "getBaseName"   getBaseName;
  directory                             =   debug'.deprecated "getDirectory"  getDirectory;

  inherit getBaseName getDirectory exists fetchGit fetchTarball fetchURL filterSource from fromSet hash import
          importScoped importWithContext nixPaths readDirectory readFile storeDirectory storePath toFile toStore;
}
