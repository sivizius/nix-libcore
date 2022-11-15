{ context, debug, error, intrinsics, ... }:
let
  context'                              =   context ++ [ "type" ];
  debug'                                =   debug context';

  /*
    Primitive Types:
      Bottom:   !           [ ]
      Unit:     null        [ null ]
      Boolean:  bool        [ false true ]
      Integer:  int         [ -1 1 … ]
      Float:    float       [ 1.0 … ]
      Path:     path        [ ./. … ]
      String:   string      [ "" "abc" … ]
      Function: ( T -> R )  [ ]
      List:     [ T ]       [ [ ] [ T ] … ]
      Set:      { … }       [ { } { T } { a: A } { a: A, T } … ]
      Top:      ...         [ ... ]
  */

  check#: S = null|string|{S}, T: Introspection @ S -> T -> T?
  =   signature:
      value:
        if      signature == null
        then
          null
        else if intrinsics.isString  signature
        then
          let
            signature'                  =   intrinsics.typeOf value;
          in
            if signature' == signature  then value
            else  debug'.panic "check" "${signature} expected, got ${signature'}"
        else if intrinsics.isList    signature
        then
          # Check Variants (any)
          value
        else if intrinsics.isAttrs     signature
        then
          # Check Fields (all)
          value
        else
          debug'.panic "check" "Invalid signature";

  check'#: S = null|string|{S}, T: Introspection @ S -> T -> T?
  =   signature:
      value:
        let
          value'                        =   check' signature value;
        in
          value;
          /*if      isSet   value'  then  value'
          else if isNull  value'  then  {}
          else                          { _ = value'; };*/

  enum#: T @ string -> { T } -> type
  =   __type__: # Unfortunately, we need a unique name here, could be solved with reflection
      { ... } @ variants:
        let
          isValidTag#: string -> bool
          =   tag:
                {
                  __constructor__       =   false;
                  __functor             =   false;
                  __methods__           =   false;
                  __name__              =   false;
                  __tag__               =   false;
                  __traits__            =   false;
                  __type__              =   false;
                }.${tag} or true;

          mapVariants#: F = ... -> Type::Variant @ { ... } -> { F }
          =   intrinsics.mapAttrs
              (
                __tag__:
                signature:
                  if isValidTag __tag__
                  then
                    if signature == null
                    then
                      { inherit __type__ __tag__; __traits__ = null; }
                    else
                      (
                        value:
                          ( check' signature value )
                          //  { inherit __type__ __tag__; __traits__ = null; }
                      )
                  else
                    debug'.panic [ "enum" "mapVariants" ] "Tag cannot be ${__tag__}!"
              );
        in
          ( mapVariants variants )
          //  {
                __name__                =   __type__;
                __constructor__         =   _: debug'.panic "enum" "Enum-type ${__type__} does not have a constructor!";
                __functor
                =   { __constructor__, ... }:
                      __constructor__;
                __methods__             =   { };
                __traits__              =   { };
                __type__                =   "type";
              };

  struct#: string -> { string } -> type
  =   __type__: # Unfortunately, we need a unique name here, could be solved with reflection
      { ... } @ signature:
      {
        __name__                        =   __type__;
        __constructor__                 =   check';
        __functor
        =   { __constructor__, __methods__, __traits__, ... }:
            value:
              ( __constructor__ signature value )
              //  __methods__
              //  { inherit __traits__ __type__; };
        __methods__                     =   { };
        __traits__                      =   { };
        __type__                        =   "type";
      };

  trait#: string -> ({ ... } -> { ... }) -> trait
  =   name: # Unfortunately, we need a unique name here, could be solved with reflection
      implement:
        let
          useAsTrait
          =   { __traits__, ... } @ object:
                let
                  methods
                  =   __traits__.${name}
                  or  (
                        debug'.panic "trait"
                        {
                          data          =   object;
                          text          =   "Object does not implement trait »${name}«";
                        }
                      );
                in
                  methods;

          implementForType
          =   { __traits__, ... } @ object:
              { ... } @ required:
                object
                //  {
                      __traits__
                      =   __traits__
                      //  {
                            ${name}
                            =   required
                            //  ( implement required );
                          };
                    };
        in
        {
          __name__                      =   name;
          __type__                      =   "trait";
          __functor#: T: Object @ self -> T -> ({ ... } -> T)|T
          =   { ... } @ self:
              { __type__, ... } @ object:
                if __type__ == "type"
                then
                  implementForType object
                else
                  useAsTrait object;
        };

  construct#: type -> ( signature -> ... -> ... ) -> type
  =   { __type__, ... } @ type:
      __constructor__:
        if __type__ == "type"
        then
          type // { inherit __constructor__; }
        else
          debug'.panic "construct" "Cannot implement constructor for something, that is not a type-object!";

  impl#: type -> { ... -> ... } -> type
  =   { __type__, __methods__, ... } @ type:
      methods:
        if __type__ == "type"
        then
          type
          //  {
                __methods__             =   __methods__ // methods;
              }
        else
          debug'.panic "impl" "Cannot implement methods for something, that is not a type-object!";

  # Get Type
  get#: T: Introspection @ T -> string
  =   value:
        let
          type                          =   getPrimitive value;
        in
          if type == "set"
          then
            value.__type__ or type
          else
            type;

  getPrimitive#: T: Introspection @ T -> string
  =   intrinsics.typeOf
  or  (
        value:
          if value == true || value == false  then  "bool"
          else if value == null               then  "null"
          else debug'.panic "getPrimitive" "Cannot determine type!"
      );

  # Type Checks
  match# T: Introspection, R1, R2, R3, R4, R5, R6, R7, R8, R9
  #@  T
  #-> { bool: R1, float: R2, int: R3, lambda: R4, list: R5, null: R6, path: R7, set: R8, string: R9 }
  #-> R
  =   value:
      { bool, float, int, lambda, list, null, path, set, string } @ select:
        select.${getPrimitive value};

  matchOrDefault# T: Introspection, D, R1, R2, R3, R4, R5, R6, R7, R8, R9
  #@  T
  #-> { bool: R1, float: R2, int: R3, lambda: R4, list: R5, null: R6, path: R7, set: R8, string: R9 }
  #-> D
  #-> R | D
  =   value:
      { ... } @ select:
      default:
        select.${getPrimitive value} or default;

  # T -> M ->  ... | !
  # where
  #   M: { ... }[typeOf T] or !,
  #   T, ...: Any
  matchOrFail
  =   value:
      { ... } @ select:
        select.${getPrimitive value}
        or  ( debug'.panic "matchOrFail" "Type ${getPrimitive value} was not handled" );

  matchPrimitive                        =   match;

  # Simple Type Checks
  isBool#: T: Introspection @ T -> bool
  =   intrinsics.isBool     or  ( value: value == true || value == false );

  isDerivation
  =   value:
        intrinsics.isAttrs value && value.type or null == "derivation";

  isFloat#: T: Introspection @ T -> bool
  =   intrinsics.isFloat    or  ( value: getPrimitive value == "float"  );

  isInteger#: T: Introspection @ T -> bool
  =   intrinsics.isInt      or  ( value: getPrimitive value == "int"    );

  isLambda#: T: Introspection @ T -> bool
  =   intrinsics.isFunction or  ( value: getPrimitive value == "lambda" );

  isList#: T: Introspection @ T -> bool
  =   intrinsics.isList     or  ( value: getPrimitive value == "list"   );

  isNull#: T: Introspection @ T -> bool
  =   value: value == null;

  isNumber#: T: Introspection @ T -> bool
  =   value: isInteger value || isFloat value;

  isPath#: T: Introspection @ T -> bool
  =   intrinsics.isPath     or  ( value: getPrimitive value == "path"   );

  isSet#: T: Introspection @ T -> bool
  =   intrinsics.isAttrs    or  ( value: getPrimitive value == "set"    );

  isString#: T: Introspection @ T -> bool
  =   intrinsics.isString   or  ( value: getPrimitive value == "string" );

  maybeBool#: T: Introspection @ T -> bool
  =   value: isBool       value || isNull value;

  maybeDerivation#: T: Introspection @ T -> bool
  =   value: isDerivation value || isNull value;

  maybeFloat#: T: Introspection @ T -> bool
  =   value: isFloat      value || isNull value;

  maybeInteger#: T: Introspection @ T -> bool
  =   value: isInteger    value || isNull value;

  maybeLambda#: T: Introspection @ T -> bool
  =   value: isLambda     value || isNull value;

  maybeList#: T: Introspection @ T -> bool
  =   value: isList       value || isNull value;

  maybeNumber#: T: Introspection @ T -> bool
  =   value: isNumber     value || isNull value;

  maybePath#: T: Introspection @ T -> bool
  =   value: isPath       value || isNull value;

  maybeSet#: T: Introspection @ T -> bool
  =   value: isSet        value || isNull value;

  maybeString#: T: Introspection @ T -> bool
  =   value: isString     value || isNull value;

  expect
  =   type:
      value:
        let
          type'                         =   getPrimitive value;
        in
          if type' == type
          then
            value
          else
            debug'.panic "expect" "${type} expected, got ${type'}";
in
{
  never                                 =   debug'.panic "never" "Cannot assign the bottom type to anything!" (error.panic "never");
  inherit expect get getPrimitive;
  inherit match matchOrDefault matchOrFail matchPrimitive;
  inherit isBool isDerivation isFloat isInteger isLambda isList isNull isNumber isPath isSet isString;
  inherit maybeBool maybeDerivation maybeFloat maybeInteger maybeLambda maybeList maybeNumber maybePath maybeSet maybeString;
  inherit enum struct trait;
}
