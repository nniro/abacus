Shell script to generate an ascii soroban abacus.

                    _________________
                   | # # # # # # # # |
                   | . . . . . . . . |
                   |-----------------|
                   | . . . . . . . . |
                   | # # # # # # # # |
                   | # # # # # # # # |
                   | # # # # # # # # |
                   | # # # # # # # # |
                    -----------------


It is possible to include genAbacus.sh in another script by
first setting the variable _AS_LIBRARY=1 before importing.
Like so :

```
_AS_LIBRARY=1
. ./genAbacus.sh

genAbacus 8 30 0
```

When imported, the function itself accepts these arguments :
```
genAbacus <abacus column count> <horizontal position> <initial number value>
```

The script genAbacus.sh has a CLI to set the options.
You can view the help screen like so :

```
sh genAbacus.sh -h
```
