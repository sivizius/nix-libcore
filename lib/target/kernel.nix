{ context, debug, integer, intrinsics, list, set, string, type, ... }:
let
  debug'                                =   debug ( context ++ [ "kernel" ] );

  ExecutableFormat#: Enum { elf, macho, pe, unknown, wasm }
  =   {
        elf                             =   1;
        macho                           =   2;
        pe                              =   3;
        unknown                         =   4;
        wasm                            =   5;
      };

  Family                                =   null || { parent = Family; };

  Kernel# struct { executableFormat: ExecutableFormat, family: Family }
  =   {
        inherit ExecutableFormat Family Kernel;
        inherit all families;

        new#: ExecutableFormat -> Family -> Kernel
        =   executableFormat:
            family:
            {
              __type__                  =   "Kernel";
              __toString                =   { name, ... }: name;
              inherit executableFormat family;
            };

        isDarwin#: System -> bool
        =   { kernel, ... } @ self:
              kernel == all.darwin;

        isLinux#: System -> bool
        =   { kernel, ... } @ self:
              kernel == all.linux;

        __functor#: type -> (string | Kernel)? -> Kernel
        =   let
              fail                      =   debug'.error "Kernel";
            in
              { ... }:
              kernel:
                type.matchOrFail kernel
                {
                  null                  =   all.none;
                  string                =   all.${kernel} or (fail "Unknown kernel »${kernel}«!");
                  set                   =   if kernel.__type__ or null == "Kernel" then kernel else fail "Not a kernel!";
                };
      };

  families#: { string -> Family }
  =   {
        bsd                             =   { parent = families.unix; };
        darwin                          =   { parent = families.bsd;  };
        linux                           =   { parent = families.unix; };
        none                            =   { parent = null;          };
        unix                            =   { parent = families.none; };
        windows                         =   { parent = families.none; };
      };

  all#: { string -> Kernel }
  =   let
        inherit(Kernel) new;
        all
        =   {
              cygwin                    =   new ExecutableFormat.elf      families.linux;
              darwin                    =   new ExecutableFormat.macho    families.darwin;
              freebsd                   =   new ExecutableFormat.elf      families.bsd;
              ios                       =   new ExecutableFormat.macho    families.darwin;
              linux                     =   new ExecutableFormat.elf      families.linux;
              ghcjs                     =   new ExecutableFormat.unknown  families.none;
              genode                    =   new ExecutableFormat.elf      families.none;
              macos                     =   all.darwin;
              mmixware                  =   new ExecutableFormat.unknown  families.none;
              netbsd                    =   new ExecutableFormat.elf      families.bsd;
              none                      =   new ExecutableFormat.unknown  families.none;
              openbsd                   =   new ExecutableFormat.elf      families.bsd;
              redox                     =   new ExecutableFormat.elf      families.none;
              solaris                   =   new ExecutableFormat.elf      families.unix;
              tvos                      =   all.ios;
              wasi                      =   new ExecutableFormat.wasm     families.none;
              watchos                   =   all.ios;
              win32                     =   all.windows;
              win64                     =   all.windows;
              windows                   =   new ExecutableFormat.pe       families.windows;
            };
      in
        set.map (name: value: value // { inherit name; }) all;
in
  Kernel
