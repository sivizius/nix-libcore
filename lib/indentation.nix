{ context, debug, list, string, type, ... }:
let
  debug'                                =   debug ( context ++ [ "indentation" ] );

  inherit (type)  enum matchOrFail;
  inherit (list)  foot get ;

  Indentation                           =   enum "Indentation" { less = null; more = null; };
in
{
  inherit (Indentation) less more;

  # string -> string | [ string | bool | null ] -> string
  __functor#: self -> string | [ string | Indentation | null ] -> string
  =   self:
      { initial ? "", tab ? "  ", ... }:
      body:
      (
        list.fold
        (
          # S -> null | string | bool -> S
          # where S: { depth: uint, indent: string, result: string }
          { cache, depth, indent, lineNumber, result, tab } @ state:
          line:
            matchOrFail line
            {
              null                      =   state;
              string
              =   state
              //  {
                    lineNumber          =   lineNumber + 1;
                    result              =   "${result}${indent}${line}\n";
                  };
              set
              =   state
              //  (
                    if line.__type__ == "Indentation"
                    then
                      {
                        more
                        =   let
                              depth'    =   depth + 1;
                              cache'
                              =   if list.length cache <= depth'
                                  then
                                    cache ++ [ "${foot cache}${tab}" ]
                                  else
                                    cache;
                            in
                            {
                              cache     =   cache';
                              depth     =   depth';
                              indent    =   get cache' depth';
                            };
                        less
                        =   if depth > 0
                            then
                              let
                                depth'  =   depth - 1;
                              in
                              {
                                depth   =   depth';
                                indent  =   get cache depth';
                              }
                            else
                              debug'.panic [] "Cannot indent less than zero.";
                      }.${line.__tag__}
                    else
                      debug'.panic [] "Got set, but either string or Indentation was expected!"
                  );
            }
        )
        {
          cache                         =   [ initial ];
          depth                         =   0;
          indent                        =   initial;
          lineNumber                    =   0;
          result                        =   "";
          inherit tab;
        }
        (
          matchOrFail body
          {
            list                        =   body;
            string                      =   string.splitLines body;
          }
        )
      ).result;
}
