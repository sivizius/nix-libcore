{ context, debug, list, string, ... }:
let
  debug'                                =   debug (context ++ [ "trim" ]);

  inherit (list)    flat foot generate get head length;
  inherit (string)  concat split;

  concat'                               =   splits: concat (flat splits);
  splitSpaces                           =   split "([[:space:]]+)";

  ltrim'
  =   list:
        if head list == ""
        && list != [ "" ]
        then
          generate (x: get list ( x + 2 )) ( length list - 2 )
        else
          list;
  rtrim'
  =   list:
        if foot list == ""
        && list != [ "" ]
        then
          generate (x: get list x) ( length list - 2 )
        else
          list;
  trim'                                 =   text: flat ( rtrim' ( ltrim' ( splitSpaces text ) ) );
in
{
  ltrim                                 =   text: concat' (ltrim' (splitSpaces text));
  rtrim                                 =   text: concat' (rtrim' (splitSpaces text));
  trim                                  =   text: concat ( trim' text );
  inherit ltrim' rtrim' trim';
}
