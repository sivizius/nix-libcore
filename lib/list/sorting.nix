{ context, debug, list, type, ... }:
let
  debug'                                =   debug ( context' ++ [ "sorting" ] );

  inherit (list) empty fold generate get head length tail;

  # F -> [ T ] -> [ T ]
  # where
  #   F: T -> T -> bool,
  #   T: Any:
  funnySort
  =   let
        maxInsertion                    =   20;
      in
        lessThan:
        list:
          let
            len                         =   length list;
          in
            if      len < 2
            then
              # Empty list or just one element
              list
            else if len <= maxInsertion
            then
              # Insertion Sort, average: O(n²), maximum is O(400), so…fine?
              insertionSort lessThan list
            else
              # Merge Sort, average: O(n log(n))
              mergeSort     lessThan list;

  # F -> [ T ] -> [ T ]
  # where
  #   F: T -> T -> bool,
  #   T: Any:
  insertionSort
  =   let
        # F -> T -> [ T ] -> [ T ]
        # where
        #   F: T -> T -> bool,
        #   T: Any
        insert
        =   lessThan:
            first:
            rest:
              if rest == [ ]
              then
                [ first ]
              else
              let
                second                  =   head rest;
              in
                if lessThan first second
                then
                  [ first  ] ++ rest
                else
                  [ second ] ++ (insert lessThan first (tail rest));
      in
        lessThan:
        list:
          if list == [ ]
          then
            [ ]
          else
            insert lessThan (head list) (insertionSort (tail list));

  # F -> [ T ] -> [ T ]
  # where
  #   F: T -> T -> bool,
  #   T: Any:
  mergeSort
  =   lessThan:
      list:
        let
          len                           =   length list;
          half                          =   len / 2;
          half'                         =   len - half;
          left                          =   generate (x: get list x             ) half;
          right                         =   generate (x: get list ( x + half )  ) half';
        in
          (
            fold
            (
              { done, left ? null, right ? null, result } @ state:
              _:
                if done
                then
                  state
                else if left == [ ]
                then
                  {
                    done                =   true;
                    result              =   result ++ right;
                  }
                else if right == [ ]
                then
                  {
                    done                =   true;
                    result              =   result ++ left;
                  }
                else if lessThan ( head left ) ( head right )
                then
                  {
                    left                =   tail left;
                    inherit right;
                    result              =   result ++ ( head left );
                  }
                else
                  {
                    inherit left;
                    right               =   tail right;
                    result              =   result ++ ( head right );
                  }
            )
            {
              done                      =   false;
              left                      =   funnySort lessThan left;
              right                     =   funnySort lessThan right;
              result                    =   [ ];
            }
            ( empty len)
          ).result;
in
  { inherit funnySort insertionSort mergeSort; }
