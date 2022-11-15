{ context, debug, intrinsics, type, ... }:
let
  debug'                                =   debug ( context ++ [ "bool" ] );

  trace = _: _;
  isBool#: T: Introspection @ T -> bool
  =   type.isBool
  or  ( value: value == true || value == false );

  expect#: T: Introspection @ T -> string -> T | !
  =   value:
      message:
        if isBool value then  value
        else                  trace value message;

  assertBool                            =   value: expect value "";
in
{
  inherit (intrinsics) false true;

  ##  Constructor for a bool:
  ##    It takes a value and if this value is a boolean,
  ##      it returns the value.
  ##    and panics otherwise.
  __functor#: T: Introspection @ Self -> T -> bool
  =   self: assertBool;

  and#: bool -> bool -> bool
  =   a: b: ( assertBool a ) && ( assertBool b );

  equivalent#: bool -> bool -> bool
  =   a: b: ( assertBool a ) == ( assertBool b );

  implies#: bool -> bool -> bool
  =   a: b: ( assertBool a ) -> ( assertBool b );

  inherit isBool;

  not#: bool -> bool
  =   a: !( assertBool a );

  or#: bool -> bool -> bool
  =   a: b: ( assertBool a ) || ( assertBool b );

  select#: bool -> T -> T -> T
  # where T: Any
  =   condition:
      ifTrue:
      ifFalse:
        if condition  then  ifTrue
        else                ifFalse;
}
