{ context, debug, expression, integer, intrinsics, list, set, type, ... } @ modules:
let
  context'                              =   context ++ [ "string" ];
  debug'                                =   debug context';

  inherit (list)  body combine concatMap filter fold foot generate get head imap map range tail;
  inherit (set)   pair;
  inherit (type)  isString matchPrimitive;

  listLength                            =   list.length;

  combine'                              =   combine (a: b: "${a}${b}");
  hexChars                              =   [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f" ];
  hexPairs                              =   combine' hexChars hexChars;

  ascii                                 =   generate (index: getChar index) 128;
  lowerAscii                            =   generate (index: getChar ( 97 + index)) 26;
  upperAscii                            =   generate (index: getChar ( 65 + index)) 26;
  char
  =   {
        backspace                       =   getChar'  "0008";
        carriageReturn                  =   "\r";
        delete                          =   getChar'  "007f";
        escape                          =   getChar'  "001b";
        horizontalTab                   =   "\t";
        lineFeed                        =   "\n";
        null                            =   "";
      };

  concat#: [ string ] -> string
  =   concatWith "";

  concatIndexMapped#: F -> [ T ] -> string
  # where
  #   F: int -> T -> string,
  #   T: Any
  =   function:
      list:
        concatIndexMappedWith function "" list;

  concatIndexMappedWith#: F -> string -> [ T ] -> string
  # where
  #   F: int -> T -> string,
  #   T: Any:
  =   function:
      seperator:
      list:
        concatWith seperator (imap function list);

  concatLines#: [ string ] -> string
  =   concatWith "\n";

  concatMapped#: F -> [ T ] -> string
  # where
  #   F: T -> string,
  #   T: Any
  =   function:
      list:
        concatMappedWith function "" list;

  concatMappedWith#: F -> string -> [ T ] -> string
  # where
  #   F: T -> string,
  #   T: Any
  =   function:
      seperator:
      list:
        concatWith seperator (map function list);

  concatWith#: string -> [ string ] -> string
  =   intrinsics.concatStringsSep
  or  (
        seperator:
        list:
          fold
          (
            result:
            entry:
              "${result}${seperator}${entry}"
          )
          ( head list )
          ( tail list )
      );

  concatWithFinal#: string -> string -> [ string ] -> string
  =   seperator:
      final:
      list:
        if listLength list > 1
        then
          "${concatWith seperator (body list)}${final}${foot list}"
        else
          head list;

  from'#: T -> string
  # where T: Any
  =   { legacy, display, depth, maxDepth }:
      value:
        matchPrimitive value
        {
          bool
          =   if legacy
              then
                if value
                then
                  "true"
                else
                  "false"
              else
                if value
                then
                  "1"
                else
                  "";
          float                         =   intrinsics.toString value;
          int                           =   integer.toString value;
          lambda
          =   if display
              then
                if legacy
                then
                  "<CODE>"
                else
                  let
                    mapArguments
                    =   { ... } @ data:
                          set.mapToList
                            (
                              key:
                              value:
                                if value
                                then
                                  "${key}?"
                                else
                                  key
                            )
                            data;
                    arguments           =   intrinsics.functionArgs value;
                  in
                    if arguments != {}
                    then
                      "({ ${concatWith ", " (mapArguments arguments)} }: …)"
                    else
                      "(_: …)"
              else
                debug'.panic "cannot coerse a function to a string";
          list
          =   if  maxDepth == null
              ||  depth < maxDepth
              then
                let
                  body
                  =   list.map
                        (
                          value:
                            "${from' { inherit display legacy maxDepth; depth = depth + 1; } value}"
                        )
                        value;
                in
                  "[ ${concatWith ", " body} ]"
              else
                if legacy
                then
                  "<CODE>"
                else
                  "…";
          null                          =   "null";
          path                          =   toString value;#"${value}";
          set
          =   if  display
              ||  !( value ? __toString )
              then
                if  maxDepth == null
                ||  depth < maxDepth
                then
                  let
                    escapeKey
                    =   key:
                          if (match "[A-Za-z_][-'0-9A-Za-z_]*" key) != null
                          then
                            key
                          else
                            "\"${key}\"";
                    body
                    =   set.mapToList
                          (
                            key:
                            value:
                              "${escapeKey key} = ${from' { inherit legacy display maxDepth; depth = depth + 1; } value};"
                          )
                          value;
                  in
                    "{ ${concatWith " " body} }"
                else
                  if legacy
                  then
                    "<CODE>"
                  else
                    "…"
              else
                value.__toString value;
          string
          =   if depth > 0
              then
                "\"${value}\""
              else
                value;
        };

  from#: T -> string
  # where T: Any
  =   from' { display = false; legacy = false; maxDepth = null; depth = 0; };

  getByte#: string -> int
  =   text: getByte' (slice 0 1 text);

  getByte'#: string -> int
  =   let
        get#: string -> int -> string
        =   text: index: slice index 1 text;

        head#: string -> char
        =   text: get text 0;

        bytes
        =   intrinsics.listToAttrs
            (
              ( generate ( value: { name = getChar value; inherit value; } 127 ) )
              ++  [
                    { name = head ( getChar' "0080" ); value = 194; }
                    { name = head ( getChar' "00c0" ); value = 195; }
                  ]
              ++  (
                    combine
                      (
                        a: b:
                        {
                          name          =   head ( getChar' "0${get hexChars a}${get hexChars (4 * b)}0" );
                          value         =   192 + 4 * a + b;
                        }
                      )
                      ( range 1 7 )
                      ( range 0 3 )
                  )
              ++  (
                    map
                      (
                        a:
                        {
                          name          =   head ( getChar' "${get hexChars a}800" );
                          value         =   224 + a;
                        }
                      )
                      ( range 0 15 )
                  )
              ++  (
                    combine
                      (
                        a: b:
                          {
                            name        =   get ( getChar' "00${get hexChars (8 + a)}${get hexChars b}" ) 1;
                            value       =   128 + 16 * a + b;
                          }
                      )
                      ( range 0  3 )
                      ( range 0 15 )
                  )
            );
      in
        char: bytes.${char};

  getChar'#: string -> char
  =   index: expression.fromJSON "\"\\u${index}\"";

  getChar#: int -> char
  =   index: get ( map getChar' (combine' hexPairs hexPairs) ) index;

  hash#: string -> string -> string
  =   intrinsics.hashString
  or  (
        type:
        text:
          {
            md5                         =   "";
            sha1                        =   "";
            sha256                      =   "";
            sha512                      =   "";
          }.${type} or (debug'.panic "hash" "Unknown hash-type »${text}«.")
      );

  isEmpty#: string -> bool
  =   text: text == "";

  length#: string -> int
  =   intrinsics.stringLength
  or  (
        text:
          let
            rest                        =   slice 1 9223372036854775807 text;
          in
            if text == "" then  0
            else                ( length rest ) + 1
      );

  lengthUTF8#: string -> int
  =   text: listLength ( toUTF8characters text );

  match#: string -> string -> [ T ]
  # where T: null | string | [ T ]
  =   intrinsics.match;

  repeat#: string -> int -> string
  =   text:
      multiplier:
        concat ( generate (_: text) multiplier );

  replace#: [ string ] -> [ string ] -> string -> string
  =   intrinsics.replaceStrings; /* should be possible to construct, but ahhh */

  slice#: int -> int -> string -> string
  =   intrinsics.substring;

  split#: string -> string -> [ T ]
  # where T: null | string | [ T ]
  =   intrinsics.split;

  splitAt#: string -> string -> [ string ]
  =   regex:
      text:
        filter
          ( line: isString line )
          ( split regex text );

  splitLines#: string -> [ string ]
  =   text: splitAt "\n" text;

  splitTabs#: string -> [ string ]
  =   text: splitAt "\t" text;

  toBytes#: string -> [ u8 ]
  =   text: map getByte' (toCharacters text);

  toCharacters#: string -> [ asciiChar ]
  =   text:
        generate (index: slice index 1 text) (length text);

  toPath#: string -> path
  =   path: "./${path}";

  toLowerCase#: string -> string
  =   let
        caseMap
        =   pair
              ( upperAscii ++ [ "Ä" "Ö" "Ü" "ẞ" ] )
              ( lowerAscii ++ [ "ä" "ö" "ü" "ß" ] );
      in
        text:
          fold
          (
            text:
            char:
              "${text}${caseMap.${char} or char}"
          )
          ""
          ( toUTF8characters text );

  toString#: T -> string
  =   intrinsics.toString
  or  (
        from' { display = false; legacy = true; maxDepth = null; depth = 0; }
      );

  toTrace#: T -> string
  # where T: Any
  =   maxDepth: from' { display = true; legacy = false; inherit maxDepth; depth = 0; };

  toTraceDeep#: T -> string
  # where T: Any
  =   toTrace null;

  toTraceShallow#: T -> string
  # where T: Any
  =   toTrace 1;

  toUpperCase#: string -> string
  =   let
        # The german letter ß (sz) cannot be at the start of a word and
        #   therefore does not have a capital form.
        # However in uppercase text, the letter ẞ is allowed,
        #   but the unicode standard still defaults to SS.
        # I do not care about that, I prefer ẞ instead.
        caseMap
        =   pair
              ( lowerAscii ++ [ "ä" "ö" "ü" "ß" ] )
              ( upperAscii ++ [ "Ä" "Ö" "Ü" "ẞ" ] );
      in
        text:
          fold
          (
            text:
            char:
              "${text}${caseMap.${char} or char}"
          )
          ""
          ( toUTF8characters text );

  toUTF8characters#: string -> [ utf8char ]
  =   text:
        let
          this
          =   fold
              (
                { result, text }:
                character:
                  if character <= char.delete
                  then
                    {
                      text                    =   "";
                      result
                      =   result
                      ++  ( if text != "" then [ text ] else [ ] )
                      ++  [ character ];
                    }
                  else
                    {
                      # Does not validate! E.g. C2 A3 A3 would be considered one char, even if this is invalid utf8!
                      text                    =   "${text}${character}";
                      inherit result;
                    }
              )
              {
                text                          =   "";
                result                        =   [ ];
              }
              ( toCharacters text );
          in
            this.result
            ++  (
                  if !( isEmpty this.text )
                  then
                    [ this.text ]
                  else
                    [ ]
                );
in
{
  __functor = self: from;
  inherit ascii char concat concatLines concatIndexMapped concatIndexMappedWith concatMapped concatMappedWith concatWith
          concatWithFinal from getByte getChar hash isEmpty length lengthUTF8 match replace repeat slice split splitAt
          splitLines toBytes toCharacters toLowerCase toPath toString toTrace toTraceDeep toTraceShallow toUpperCase toUTF8characters;
}
//  (import ./trim.nix ( modules // { context = context'; } ))