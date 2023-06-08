# MX BASIC Unit Tests

| Batch File  | Description                                |
| ----------- | ---------------------------------          |
| txt2bas.bat | Converts .bas.txt file to .bas file        |
| bas2aql.bat | Copies .bas file to AquaLite USB directory |

## File Extensions

Files with extension .bas.txt are untokenized BASIC programs.

Files with extension .bas are tokenized BASIC programs in CAQ format.

## Converting and running files

To convert file *program.bas.txt* to *program.bas*, use command line:

    txt2bas program

To copy file *program.bas* to the AquaLite USB directory use command line:

    txt2bas program

The program can then be run in aqualite using the command RUN "*program*"

Note: The script bas2aql.bat expects the environment variable %AQUALITE%
to contain the AquaLite program directory.