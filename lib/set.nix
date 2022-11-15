{ context, debug, intrinsics, list, type, ... }:
let
  debug'                                =   debug ( context ++ [ "set" ] );
  inherit (list)  find isList length;

  # string -> [ { T... } ] -> [ T ]
  # where T: Any
  collect
  =   intrinsics.catAttrs
  or  (
        name:
        list:
          list.fold
          (
            result:
            { ... } @ entry:
              if hasAttribute name entry
              then
                result ++ [ entry.${name} ]
              else
                result
          )
          [ ]
          list
      );

  filter# F -> { T } -> { T }
  # where
  #   F: string -> T -> bool,
  #   T: Any
  =   predicate:
      { ... } @ dictionary:
        filterByName dictionary (list.filter (name: predicate name dictionary.${name}) (names dictionary));

  # { T } -> [ string ] -> { T... }
  # where T: Any:
  filterByName
  =   { ... } @ dictionary:
      keys:
        fromList (list.map (name: { inherit name; value = dictionary.${name}; }) keys);

  filterKeys# F -> { T } -> { T }
  # where
  #   F: string -> bool,
  #   T: Any
  =   predicate:
      { ... } @ dictionary:
        filterByName dictionary (list.filter predicate (names dictionary));

  filterValue# F -> { T } -> { T }
  # where
  #   F: T -> bool,
  #   T: Any
  =   predicate:
      { ... } @ dictionary:
        filterByName dictionary (list.filter (name: predicate dictionary.${name}) (names dictionary));

  # F -> S -> { T... } -> S
  # where
  #   F: S -> string -> T -> S,
  #   T, S: Any:
  fold
  =   function:
      state:
      { ... } @ dictionary:
        list.fold
        (
          state:
          name:
            function state name dictionary.${name}
        )
        state
        ( names dictionary );

  # [ { name: string, value: T } ] -> { T... }
  # where T: Any:
  fromList
  =   intrinsics.listToAttrs
  or  (
        list:
          list.fold
          (
            { ... } @ result:
            { name, value }:
              # [ { name = "a"; value = 1; } { name = "a"; value = 2; } ] -> { a = 1; }
              {
                ${name}                 =   value;
              } //  result
          )
          { }
          list
      );

  # D -> [ T ] -> { D... }
  # where
  #   F: T -> R,
  #   T, R: Any:
  fromListDefault
  =   value:
      list:
        fromList (list.map (name: { inherit name value; }));

  # F -> [ T ] -> { R... }
  # where
  #   F: T -> { name: string, value: R },
  #   T, R: Any:
  fromListMapped
  =   function:
      list:
        fromList (list.map function list);

  # F -> [ T ] -> { R... }
  # where
  #   F: int -> T -> { name: string, value: R },
  #   T, R: Any:
  fromListIMapped
  =   function:
      list:
        fromList (list.imap function list);

  # F -> [ T ] -> { R... }
  # where
  #   F: T -> R,
  #   T, R: Any:
  fromListMappedValue
  =   function:
      list:
        fromList (list.map (name: { inherit name; value = function name; }) list);

  # F -> [ T ] -> { R... }
  # where
  #   F: int -> T -> R,
  #   T, R: Any:
  fromListIMappedValue
  =   function:
      list:
        fromList (list.imap (index: name: { inherit name; value = function index name; }) list);

  # string -> { T... } -> T
  # where T: Any:
  get
  =   intrinsics.getAttr
  or  (
        name:
        dictionary:
          dictionary.${name}
      );

  # string -> { T... } -> D -> T | D
  # where T, D: Any:
  getOr
  =   intrinsics.getAttr
  or  (
        name:
        dictionary:
        default:
          dictionary.${name} or default
      );

  # string -> { ... } -> bool
  hasAttribute
  =   intrinsics.hasAttr
  or  (
        name:
        dictionary:
          dictionary.${name} or true == dictionary.${name} or false
      );

  # { ... } -> { ... } -> { ... }
  intersect
  =   intrinsics.intersectAttrs
  or  (
        left:
        right:
          list.fold
          (
            result:
            entry:
              if hasAttribute entry right
              then
                result // { ${entry} = right.${entry}; }
              else
                result
          )
          { }
          (names left)
      );

  # F -> { T... } -> { R... }
  # where
  #   F: string -> T -> R,
  #   T, R: Any:
  map
  =   intrinsics.mapAttrs
  or  (
        function:
        { ... } @ dictionary:
          list.fold
          (
            result:
            name:
              result
              //  {
                    ${name}             =   function name dictionary.${name};
                  }
          )
          { }
          ( names dictionary )
      );

  mapNamesAndValues#: F -> { T... } -> { R... }
  # where
  #   F: string -> T -> { name: string, value: R }
  #   T, R: Any,
  =   function:
      dictionary:
        fromList ( mapToList function dictionary );

  # F -> { T... } -> { R... }
  # where
  #   F: T -> R,
  #   T, R: Any:
  mapValues
  =   function:
        map
        (
          _:
          value:
            function value
        );

  # F -> { T... } -> [ R ]
  # where
  #   F: string -> T -> R,
  #   T, R: Any:
  mapToList
  =   function:
      { ... } @ dictionary:
        values ( map function dictionary );

  # { ... } -> [ string ]
  names                                 =   intrinsics.attrNames;

  pair#: n, T @ n:[ string ] -> n:[ T ] -> { T }
  =   names:
      values:
        if  isList names
        &&  isList values
        &&  length names == length values
        then
          fromListIMappedValue (index: name: list.get values index) names
        else
          debug'.panic "pair" "Names and Values must be two lists of same length!";

  pairNameWithValue
  =   name: value: { inherit name value; };

  # { ... } -> [ string ] -> { ... }:
  remove
  =   intrinsics.removeAttrs
  or  (
        { ... } @ dictionary:
        list:
          list.fold
          (
            result:
            name:
              if !( find list name )
              then
                result
                //  {
                      ${name}           =   dictionary.${name};
                    }
              else
                result
          )
          { }
          (names dictionary)
      );

  # { T... } -> string -> T
  # where T: Any:
  select                                =   { ... } @ dictionary: field: dictionary.${field};

  # { ... } -> [ T ]
  # where T: Any
  values
  =   intrinsics.attrValues
  or  (
        { ... } @ dictionary:
        list.map (name: dictionary.${name}) (names dictionary)
      );
in
{
  inherit collect filter filterByName filterKeys filterValue fold fromList fromListDefault fromListMapped mapNamesAndValues
          fromListMappedValue get getOr hasAttribute intersect map mapToList mapValues names pair pairNameWithValue
          remove select values;
}
