{ context, debug, intrinsics, ... }:
let
  debug'                                =   debug ( context ++ [ "internal" ] );

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
in
{
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
}