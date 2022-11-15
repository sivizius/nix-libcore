{ context, debug, expression, float, intrinsics, list, string, type, ... }:
let
  debug'                                =   debug ( context ++ [ "integer" ] );
  inherit (type) isInteger matchOrDefault;

  from#: int | float | string -> int
  =   value:
      matchOrDefault value
      {
        float                           =   float.round' value;
        int                             =   value;
        string
        =   let
              result                    =   toInteger value;
            in
              if result != null
              then
                result
              else
                debug.panic "from" "Could not convert string ${value} to int!";
      }
      ( debug'.panic "from" "Could not convert type ${type.get value} to int!" );

  toInteger#: string -> int | null
  =   value:
        let
          value'                        =   string.match "([+-])?0*(.+)" value;
          result                        =   expression.fromJSON ( list.get value' 1);
          sign                          =   list.head value';
        in
          if isInteger result
          then
            if sign == "-"
            then
              ( - result )
            else
              result
          else
            null;

  divmod
  =   value:
      modulus:
        let
          value'                        =   value / modulus;
        in
        {
          value                         =   value';
          rest                          =   value - value' * modulus;
        };

  digit
  =   list.get [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" ];

  toString'
  =   { value, rest }:
        if value < 10
        then
          "${digit value}${digit rest}"
        else
          "${toString' (divmod value 10)}${digit rest}";

  toString
  =   intrinsics.toString
  or  (
        value:
          if value < 0
          then
            toString (0 - value)
          else if value < 10
          then
            digit value
          else
            toString' (divmod value 10)
      );
in
{
  __functor                             =   self: from;
  inherit from isInteger toString;
}
