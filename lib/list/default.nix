{ context, debug, intrinsics, set, type, ... } @ modules:
let
  context'                              =   context ++ [ "list" ];
  debug'                                =   debug context';

  inherit (set)   pairNameWithValue;
  inherit (type)  isList;

  all#: T, F: T -> bool @ F -> [ T ] -> bool
  =   intrinsics.all
  or  (
        predicate:
        list:
          fold
          (
            state:
            entry:
              state && ( predicate entry )
          )
          true
          list
      );

  any#: T, F: T -> bool @ F -> [ T ] -> bool
  =   intrinsics.any
  or  (
        predicate:
        list:
          fold
          (
            state:
            entry:
              state || ( predicate entry )
          )
          false
          list
      );

  areEqual#: T: Equal @ [ T ] -> [ T ] -> bool
  =   left:
      right:
        let
          length                        =   length left;
        in
        ( length == length right )
        &&  (
              fold
              (
                result:
                index:
                  result && ( get left index == get right index )
              )
              true
              ( range 0 length )
            );

  body#: T @ [ T ] -> [ T ] | !
  =   list:
        generate
          ( index: get list index )
          ( ( length list ) - 1 );

  bodyOr#: T, D @ [ T ] -> D -> [ T ] | [ D ]
  =   list:
      default:
        if isEmpty list
        then
          [ default ]
        else
          body list;

  chain# T, U @ [ T ] -> [ U ] -> [ T | U ]
  =   left:
      right:
        left ++ right;

  # F -> [ T ] -> [ T ] -> [ T ]
  # where
  #   F: T -> T -> int, /* -1: l < r, 0: l == r, 1: l > r */
  #   T: Ordable:
  compare
  =   compareElements:
      left:
      right:
        let
          compareLists
          =   compare:
              left:
              right:
              length:
              (
                fold
                (
                  result:
                  index:
                    if result == 0
                    then
                      compareElements
                        (get left  index)
                        (get right index)
                    else
                      result
                )
                0
                ( range 0 length )
            ).result;
          lengthLeft                    =   length left;
          lengthRight                   =   length right;
        in
          if      lengthLeft  ==  lengthRight
          then
            compareLists compare left right lengthRight
          else if lengthLeft  >   lengthRight
          then
            let
              result                    =   compareLists compare left right lengthRight;
            in
              if result == 0 then 1 else result
          else
            let
              result                    =   compareLists compare left right lengthLeft;
            in
              if result == 0 then (-1) else result;

  # F -> [ T ] -> [ U ] -> [ R ]
  # where
  #   F: T -> U -> R,
  #   T, U, R: Any:
  combine
  =   function:
      left:
      right:
        concatMap (value: map (value': function value value') right) left;

  # [ [ T ] ] -> [ T ]
  # where T: Any:
  concat
  =   intrinsics.concatLists
  or  (
        list:
          fold
          (
            result:
            entry:
              result ++ entry
          )
          [ ]
          list
      );

  # F -> [ T ] -> [ U ]
  # where
  #   F: T -> U,
  #   T, U: Any:
  concatMap
  =   intrinsics.concatMap
  or  (
        function:
        list:
          concat ( map function list )
      );

  # int -> [ null ]:
  empty
  =   length:
        generate (_: null) length;

  # F -> [ T ] -> [ T ]
  # where
  #   F: T -> bool,
  #   T: Any:
  filter
  =   intrinsics.filter
  or  (
        predicate:
        list:
          fold
          (
            result:
            entry:
              if predicate entry
              then
                result ++ [ entry ]
              else
                result
          )
          [ ]
          list
      );

  # [ T ] -> T -> bool
  # where T: Any:
  find
  =   intrinsics.elem
  or  (
        list:
        value:
          if      isEmpty list        then  false
          else if head list == value  then  true
          else                              find (tail list) value
      );

  flat#: T, U: ![ ... ] @ [ [ T ] | U ] -> [ T | U ]
  =   list:
        fold
        (
          result:
          entry:
            if isList entry
            then
              result ++ entry
            else
              result ++ [ entry ]
        )
        [ ]
        list;

  flatDeep#: T, U: ![ ... ] @ [ [ T ] | U ] -> [ U ]
  =   list:
        fold
        (
          result:
          entry:
            if isList entry
            then
              result ++ ( flatDeep entry )
            else
              result ++ [ entry ]
        )
        [ ]
        list;

  # F -> S -> [ T ] -> S
  # where
  #   F: S -> T -> S,
  #   S, T: Any:
  fold
  =   intrinsics.foldl'
  or  (
        next:
        init:
        list:
          fold' next init list
      );

  # F -> S -> [ T ] -> S
  # where
  #   F: S -> T -> S,
  #   S, T: Any:
  fold'
  =   intrinsics.foldl'
  or  (
        next:
        init:
        list:
          if list != [ ]
          then
            fold'
              next
              ( next init ( head list ) )
              ( tail list )
          else
            init
      );

  # F -> S -> [ T ] -> S
  # where
  #   F: S -> T -> S,
  #   S, T: Any:
  foldReversed
  =   let
        fold'
        =   next:
            init:
            list:
              if list != [ ]
              then
                fold'
                  next
                  ( next init ( foot list ) )
                  ( body list )
              else
                init;
      in
        (
          next:
          init:
          list:
            fold' next init list
        );

  # [ T ] -> T
  # where T: Any:
  foot
  =   list:
        get list (length list - 1);

  # [ T... ] | [ ] -> D -> T | D
  # where T, D: Any:
  footOr                                =   list: default: if isEmpty list then default else foot list;

  # F -> int -> [ T ]
  # where F: int -> T:
  generate
  =   intrinsics.genList
  or  (
        generator:
          let
            generate'
            =   length:
                index:
                  if length > 0
                  then
                    [ ( generator index ) ]
                    ++ ( generate' ( length - 1 ) ( index + 1 ) )
                  else
                    [ ];
          in
            length:
              generate' length 0
      );

  # [ T ] -> int -> T:
  get                                   =   intrinsics.elemAt;

  # F -> [ T ] -> { ... }
  # where
  #   F: T -> string,
  #   T: Any:
  groupBy
  =   intrinsics.groupBy
  or  (
        toName:
        list:
          fold
          (
            result:
            entry:
              let
                name                    =   toName entry;
              in
                result
                //  {
                      ${name}
                      =   ( result.${name} or [ ] )
                      ++  [ entry ];
                    }
          )
          { }
          list
      );

  # [ T ] -> T
  # where T: Any:
  head
  =   intrinsics.head
  or  (
        list:
          get list 0
      );

  # [ T ... ] | [ ] -> D -> T | D
  # where T, D: Any:
  headOr                                =   list: default: if isEmpty list then default else head list;

  isEmpty#: T @ [ T ] -> bool
  =   list: list == [ ];

  # F -> [ T ] -> [ R ]
  # where
  #   F: int -> T -> R,
  #   T, R: Any:
  imap
  =   function:
      list:
        generate (index: function index (get list index)) (length list);

  length#: T @ [ T ] -> int
  =   intrinsics.length;

  # F -> [ T ] -> [ U ]
  # where
  #   F: T -> U,
  #   T, U: Any:
  map
  =   intrinsics.map
  or  (
        function:
        list:
          generate (index: function (get list index)) (length list)
      );

  # F -> [ string ] -> { string -> T }
  # where
  #   F: string -> T,
  #   T: Any:
  mapNamesToSet
  =   function:
      names:
        toSet (map (name: pairNameWithValue name (function name)) names);

  # F -> [ T ] -> { string -> U }
  # where
  #   F: T -> { name: string, value: U },
  #   T, U: Any:
  mapValuesToSet
  =   function:
      values:
        toSet (map function values);

  # [ T ] where T: Any:
  new                                   =   [];

  # F -> [ T ] -> { right: [ T ], wrong: [ T ] }
  # where
  #   F: T -> bool,
  #   T: Any:
  partition
  =   intrinsics.partition
  or  (
        predicate:
        list:
          fold
          (
            { right, wrong }:
            value:
              if predicate value
              then
                {
                  right                 =   right ++ [ value ];
                  inherit wrong;
                }
              else
                {
                  inherit right;
                  wrong                 =   wrong ++ [ value ];
                }
          )
          {
            right                       =   [ ];
            wrong                       =   [ ];
          }
          list
      );

  optionnal#: T | null -> [ T ]
  =   value:
        if value != null
        then
          [ value ]
        else
          [ ];

  range#: int -> int -> [ int ]
  =   from:
      till:
        generate (x: x + from) (till - from + 1);

  # [ T ] -> [ T ]
  # where T: Any:
  reverse
  =   list:
        let
          length                        =   ( length list ) - 1;
        in
          generate (x: get list ( length - x)) list;

  # F -> [ T ] -> [ T ]
  # where
  #   F: T -> T -> bool,
  #   T: Any:
  sort                                  =   intrinsics.sort or sorting.funnySort;

  sorting                               =   import ./sorting.nix ( modules // { context = context ++ [ "list" ]; } );

  # [ T ] -> [ T ]
  # where T: Any:
  tail
  =   intrinsics.tail
  or  (
        list:
          generate
            ( index: get list ( index + 1 ) )
            ( ( length list ) - 1 )
      );

  # [ ... ] | [ ] -> D -> [ ... ] | D
  # where T, D: Any:
  tailOr                                =   list: default: if isEmpty list then default else tail list;

  # [ { name: string, value: T } ] -> { T... }
  # where T: Any:
  toSet
  =   intrinsics.listToAttrs
  or  (
        list:
          fold
          (
            result:
            { name, value }:
              result // { ${name} = value; }
          )
          { }
          list
      );

  # [ T ] -> [ U ] -> [ [ T U ] ]
  # where T, U: Any:
  zip
  =   left:
      right:
        generate (x: [ (get left x) (get right x) ] ) (length left);
in
{
  mapToSet                              =   debug'.deprecated "mapToSet" "mapNamesToSet" mapNamesToSet;
  inherit all any areEqual body bodyOr chain combine compare concat concatMap empty filter find flat fold foldReversed
          foot footOr generate get head headOr imap isList isEmpty length map mapNamesToSet mapValuesToSet new partition sort
          sorting tail tailOr toSet zip;
}
