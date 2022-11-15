{ intrinsics, type, ... }:
{
  default
  =   value:
      other:
        if value != null
        then
          value
        else
          other;
  inherit (intrinsics)  null;
  inherit (type)        isNull;
}