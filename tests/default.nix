{ error, ... }:
{
  foo
  =   {
        success                         =   true;
        bar
        =   {
              mew                       = [ 1 2 ];
              miau                      =   foo: __trace foo true;
              hmm                       =   [ { a = 1; } ];
            };
      };
}
