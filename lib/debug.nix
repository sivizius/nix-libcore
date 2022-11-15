{ error, function, intrinsics, list, set, string, type,
  logLevel    ? 6,
  fatalLevel  ? 2,
  ...
}:
let
  inherit (type)    matchOrFail matchPrimitive isList;
  inherit (string)  char concatWith splitLines trim;

  Body
  =   string
  ||  [ string ]
  ||  {
  #     depth:  integer?                = null,
  #     fatal:  bool                    = false,
  #     text:   ([ string ] | string)?  = [],
  #     when:   bool                    = true,
  #     show:   bool                    = false,
  #     data:   any                     = null,
      }
  || null;

  Source
  =   string
  ||  [ string ]
  ||  null;

  b                                     =   char.backspace;
  e                                     =   char.escape;
  b'                                    =   "${b}${b}${b}${b}${b}${b}${b}";
  b''                                   =   "${b'}${b'}${b'}${b'}${b'}${b'}${b'}${b}${b}${b}${b}${b}";
  e'                                    =   cfg: str: "${e}[${cfg}m${str}${e}[0m";
  print# { level, colour, name } -> Source -> Body -> (T -> T) | !
  =   { level, colour, name } @ config:
      source:
      body:
        let
          toLines                       =   text: splitLines (trim text);
          fromSet
          =   let
                toLines'
                =   text:
                      matchOrFail text
                      {
                        null            =   [ ];
                        list            =   text;
                        string          =   toLines text;
                      };
              in
                {
                  depth ? null,
                  fatal ? false,
                  text  ? [ ],
                  when  ? true,
                  show  ? false,
                  data  ? null,
                } @ this:
                  {
                    inherit fatal show when;
                    body
                    =   ( toLines' text )
                    ++  (
                          if this ? data
                          then
                            [ (string.toTrace depth data) ]
                          else
                            [ ]
                        );
                  };

          body'
          =   matchOrFail body
              {
                null                    =   { body = [ ];           when = true; fatal = false; show = false; };
                list                    =   { inherit body;         when = true; fatal = false; show = false; };
                set                     =   fromSet body;
                string                  =   { body = toLines body;  when = true; fatal = false; show = false; };
              };
        in
          print' config source body';

  print'#:
  # { level: integer, colour: string, name: string }
  # -> Source
  # -> { body: [ string ], fatal: bool, show: bool, when: bool }
  # -> (T -> T) | !
  =   { level, colour, name }:
      source:
      { body, fatal, show, when }:
        let
          message
          =  let
              foldLines
              =   list.fold
                    ( text: line: "${text}\n| ${line}" )
                    "";
              source'
              =   matchOrFail source
                  {
                    null                =   "???";
                    list                =   concatWith " → " source;
                    string              =   source;
                  };
            in
              "[${name}] {${source'}}${foldLines body}";
        in
          if  when
          &&  ( level <= fatalLevel || level <= logLevel )
          then
            (
              if  fatal
              ||  level <= fatalLevel
              then
                intrinsics.trace "${b'}${e' colour message}" (error.panic "See Error Message Above")
              else if show
              then
                value: intrinsics.trace "${b'}${e' colour "${message}\n| ${string.toTraceDeep value}"}" value
              else
                intrinsics.trace "${b'}${e' colour message}"
            )
          else
            (_:_);

  levels
  =   {
        dafuq                           =   { level = 0; colour = "95"; name = "DAFUQ"; }; # This should not even happen.
        panic                           =   { level = 1; colour = "31"; name = "PANIC"; }; # You will not get a result.
        error                           =   { level = 2; colour = "91"; name = "ERROR"; }; # You will not get, what you expect.
        warn                            =   { level = 3; colour = "93"; name = "WARN";  }; # You might not get, what you expect.
        info                            =   { level = 4; colour = "92"; name = "INFO";  }; # Usefull information, which are fine.
        debug                           =   { level = 5; colour = "96"; name = "DEBUG"; }; # Specific Information.
        trace                           =   { level = 6; colour = "37"; name = "TRACE"; }; # Single code paths.
      };

  printers#: F, T: { string -> F }
  # where F: Source -> Body -> (T -> T) | !
  =   set.mapValues print levels;
in
  printers
  //  {
        deprecated                      =   src:  printers.warn   src "Deprecated: Use ${list.foot src} instead!";
        unimplemented                   =   src:  printers.panic  src "Not implemented yet, please be patient!";
        unreachable                     =   src:  printers.dafuq  src "Unreachable…or at least should not have been o.O!";

        __functor
        =   self:
            context:
            (
              set.map
              (
                name:
                method:
                  if name == "__functor"
                  then
                    method
                  else
                    source:
                      method
                      (
                        context
                        ++  (
                              if isList source
                              then
                                source
                              else
                                [ source ]
                            )
                      )
              )
              self
            );
      }
