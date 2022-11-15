{ context, debug, expression, intrinsics, list, string, type, ... }:
let
  debug'                                =   debug ( context ++ [ "number" ] );

  inherit (expression)  fromJSON;
  inherit (type)        getPrimitive matchOrDefault;
  inherit (list)        fold foldReversed generate get head;
  inherit (string)      concat concatMappedWith length match slice toCharacters;

  assertNumber#: int | float -> int | float | !
  =   value:
        matchNumber value
        {
          float                         =   value;
          int                           =   value;
        };

  matchNumber#: T -> { int: R, float: R } -> R | !
  # where T, R: Any
  =   value:
      { int, float } @ select:
        matchOrDefault
          value
          select
          ( debug'.panic "matchNumber" "Value is not a number: Neither int nor float!" );

  abs#: int | float -> int | float
  =   value:
        let
          value'                        =   assertNumber value;
        in
          if value' < 0
          then
            ( 0 - value' )
          else
            value';

  add#: int | float -> int | float -> int | float
  =   intrinsics.add or (a: b: ( assertNumber a ) + ( assertNumber b ));

  and#: int -> int -> int
  =   intrinsics.bitAnd;

  ceil#: int | float -> int
  =   intrinsics.ceil
  or  (
        let
          nullDec                       =   ( split 1.0 ).dec;
        in
          value:
            matchNumber value
            {
              int                       =   value;
              float
              =   let
                    parts               =   split value;
                    int                 =   toInteger parts.int;
                  in
                    if  parts.dec == nullDec
                    ||  value < 0
                    then
                      int
                    else
                      int + 1;
            }
        );

  div#: int | float -> int | float -> int | float
  =   intrinsics.div or (a: b: ( assertNumber a ) / ( assertNumber b ));

  floor#: int | float -> int
  =   intrinsics.floor
  or  (
        value:
          matchNumber
          {
            int                         =   value;
            float                       =   0 - ceil ( 0 - value );
          }
      );

  lessThan#: int | float -> int | float -> int | float
  =   intrinsics.lessThan or (a: b: ( assertNumber a ) < ( assertNumber b ));

  moreThan#: int | float -> int | float -> int | float
  =   a: b: ( assertNumber a ) > ( assertNumber b );

  mul#: int | float -> int | float -> int | float
  =   intrinsics.mul or (a: b: ( assertNumber a ) * ( assertNumber b ));

  neg#: int | float -> int | float
  =   value: ( 0 - ( assertNumber value ) );

  or#: int -> int -> int
  =   intrinsics.bitOr;

  pow#: int -> int | float -> int | float
  =   let
        pow#: int -> int | float -> int | float
        =   base:
            exp:
              fold
                (y: x: x*y)
                1.0
                (generate (x: base) exp);
      in
        base:
        exp:
          if exp < 0.0
          then
            pow ( 1.0 / base ) ( 0 - exp )
          else
            pow ( 1.0 * base ) exp;

  round#: int | float -> int
  =   value:
        #debug.info "round" { data = { inherit value; value' = value + 0.5; round = floor ( value + 0.5 ); }; }
        matchNumber value
        {
          int                           =   value;
          float                         =   round' value;
        };

  round'#: float -> int
  =   value: floor ( value + 0.5 );

  split#: value -> { int: string, dec: string }
  =   value:
        let
          list                          =   match "([^.]+)[.](.+)" (string value);
          int                           =   get list 0;
          dec                           =   get list 1;
        in
          { inherit int dec; };

  sub#: int | float -> int | float -> int | float
  =   intrinsics.sub or (a: b: (assertNumber a) - (assertNumber b));

  sum#: [ int | float ] -> int | float
  =   fold (result: value: result + value) 0;

  toFloat#: int | float | string -> float
  =   value:
        matchOrDefault value
        {
          int                           =   1.0 * value;
          float                         =   value;
          string
          =   let
                parts                   =   split value;
                len                     =   length parts.dec;
              in
                ( ( 1.0 * ( toInteger parts.dec ) ) / ( pow 10 len ) )
                + ( toInteger parts.int );
        }
        ( debug'.panic "toFloat" "Cannot convert ${getPrimitive value} to float." );


  toInteger#: int | float | string -> int
  =   value:
      matchOrDefault value
      {
        float                           =   round' value;
        int                             =   value;
        string
        =   let
              result                    =   toInteger' value;
            in
              if result != null
              then
                result
              else
                debug.panic "toInteger" "Could not convert string ${value} to int!";
      }
      ( debug'.panic "toInteger" "Could not convert type ${type value} to int!" );

  toInteger'#: string -> int | null
  =   value:
        let
          value'                        =   match "([+-])?0*([0-9.][0-9]+)" value;
          result                        =   fromJSON ( get value' 1);
          sign                          =   head value';
        in
          if value' != null
          && type.isInteger result
          then
            if sign == "-"
            then
              ( - result )
            else
              result
          else
            null;

  toStringWithMaximumPrecision#: int | float -> int -> string
  =   value:
      precision:
        if precision > 0
        then
          foldReversed
          (
            state:
            character:
              if state != null          then  "${character}${state}"
              else if character == "."  then  ""
              else if character != "0"  then  character
              else                            null
          )
          null
          ( toCharacters ( toStringWithPrecision value precision ) )
        else
          toStringWithPrecision value precision;

  splitFloat
  =   value:
      precision:
        let
          factor                        =   pow 10 precision;
          value'                        =   string ( round ( value * factor ) );
          length                        =   string.length value';
        in
        {
          integer                       =   string.slice 0 (length - precision) value';
          decimal                       =   string.slice (length - precision) precision value';
        };

  toStringWithPrecision#: int | float -> int -> string
  =   value:
      precision:
        let
          value'                        =   splitFloat value          precision;
          valuePos                      =   splitFloat (value + 1.0)  precision;
          valueNeg                      =   splitFloat (value - 1.0)  precision;
          valueWithPrecision
          =   matchOrDefault precision
              {
                int
                =   if precision == 0
                    then
                      "${string (round value)}"
                    else if value >= 1.0
                    || value <= (-1.0)
                    then
                      "${value'.integer}.${value'.decimal}"
                    else if value >= 0
                    then
                      "0.${valuePos.decimal}"
                    else
                      "-0.${valueNeg.decimal}";
                null                    =   toSignificantString value;
              }
              ( debug'.panic "toStringWithPrecision" "Invalid Precision: Int or null expected!" );
        in
          matchOrDefault value
          {
            float                       =   valueWithPrecision;
            int                         =   valueWithPrecision;
            list                        =   concatMappedWith (x: toStringWithPrecision x precision) ", " value;
            set
            =   (
                  { from, till }:
                  "${toStringWithPrecision value.from precision}–${toStringWithPrecision value.till precision}"
                )
                value;
          }
          ( debug'.panic "toStringWithPrecision" "Value must be a numeric value like int or float!" );

  toSignificantString#: int | float -> string
  =   value:
        let
          parts                         =   split value;
          significant
          =   fold
              (
                state:
                character:
                  if state.done
                  then
                    state
                  else if state.rest == "1"
                  then
                    state // { rest = "1${character}"; }
                  else if state.rest != null
                  then
                    state // { rest = string ( round ( ( toInteger "${state.rest}${character}" ) / 10.0 ) ); done = true; }
                  else if character == "0"
                  then
                    state // { result = "${state.result}0"; }
                  else
                    state // { rest = character; }
              )
              {
                result                  =   "";
                rest                    =   null;
                done                    =   false;
              }
              ( toCharacters parts.dec );
          rest
          =   if significant.rest != null
              then
                ".${significant.result}${significant.rest}"
              else
                "";
        in
          matchNumber value
          {
            int                         =   string value;
            float
            =   if value > 1
                || value < ( 0 - 1 )
                then
                  parts.int
                else
                  "${if value < 0 then "-" else ""}0${rest}";
          };
  xor#: int -> int -> int
  =   intrinsics.bitXor;
in
{
  inherit abs add and ceil div floor lessThan moreThan mul neg or pow round round' split sub sum xor;
  inherit toFloat toInteger toInteger' toSignificantString toStringWithMaximumPrecision toStringWithPrecision;
}
