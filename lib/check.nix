{ debug, intrinsics, list, path, set, string, type, ... }:
let
  inherit(intrinsics) derivation tryEval;

  check
  =   value:
      arguments:
        let
          result                        =   checkOther  value;
        in
          if result.success
          then
            type.matchOrDefault result.value
            {
              list                      =   checkList   result.value;
              set                       =   checkTests  result.value arguments;
              lambda                    =   checkValue  (result.value arguments);
            }
            result
          else
          {
            success                     =   false;
            value                       =   null;
          };

  checkList
  =   value:
        list.fold
        (
          { success, value } @ state:
          entry:
            if success
            then
              let
                result                  =   checkValue entry;
              in
              {
                inherit(result) success;
                value
                =   if result.success
                    then
                      value ++ [ result.value ]
                    else
                      null;
              }
            else
              state
        )
        {
          success                       =   true;
          value                         =   [];
        }
        value;

  checkOther
  =   value:
        let
          result                        =   tryEval value;
        in
        {
          inherit(result) success;
          value
          =   if result.success
              then
                result.value
              else
                null;
        };

  checkSet
  =   { ... } @ value:
        set.fold
        (
          { success, value } @ state:
          name:
          entry:
            if success
            then
              let
                result                  =   checkValue entry;
              in
              {
                inherit(result) success;
                value
                =   if result.success
                    then
                      value //  { ${name} = result.value; }
                    else
                    {
                      success           =   false;
                      value             =   null;
                    };
              }
            else
              state
        )
        {
          success                       =   true;
          value                         =   {};
        }
        value;

  checkTests
  =   { ... } @ value:
      arguments:
        set.fold
        (
          { success, value }:
          name:
          entry:
            let
              result                    =   check entry arguments;
            in
            {
              success                   =   success && result.success;
              value                     =   value // { ${name} = result; };
            }
        )
        {
          success                       =   true;
          value                         =   {};
        }
        value;

  checkValue
  =   value:
        let
          result                        =   checkOther  value;
        in
          if result.success
          then
            type.matchOrDefault result.value
            {
              list                      =   checkList   result.value;
              set                       =   checkSet    result.value;
            }
            result
          else
          {
            success                     =   false;
            value                       =   null;
          };

  formatValue
  =   name:
      { success, value }:
        let
          name'
          =   if name != null
              then
                " ${name}"
              else
                "";
        in
          if success
          then
            "echo -e \"\\e[32m[passed]${name'}: ${string value}\\e[0m\""
          else
            "echo -e \"\\e[31m[failed]${name'}\\e[0m\"";

  format
  =   fullName:
      { value, success } @ testCases:
        if type.isSet value
        then
          string.concatLines
          (
            set.mapToList
            (
              name:
              testCases:
                let
                  name'
                  =   if fullName != null
                      then
                        "${fullName} → ${name}"
                      else
                        name;
                in
                  format name' testCases
            )
            value
          )
        else
          formatValue fullName testCases;
in
  system:
  tests:
  arguments:
    let
      tests'                            =   check tests arguments;
      builder
      =   path.toFile "builder.sh"
          ''
            #!/usr/bin/env sh
            ${format null tests'}
            ${
              if tests'.success
              then
                ''
                  echo -e "\e[32mall tests were successful!\e[0m"
                  echo "1" > $out
                  exit 0
                ''
              else
                ''
                  echo -e "\e[31msome tests failed!\e[0m"
                  exit 1
                ''
            }
          '';
    in
      derivation
      {
        inherit system;
        name                            =   "libcore-test";
        builder                         =   "/bin/sh";
        args                            =   [ builder ];
      }
