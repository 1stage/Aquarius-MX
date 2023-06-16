# MX BASIC Unit Tests

| Batch File  | Description                                |
| ----------- | ---------------------------------          |
| txt2bas.bat | Converts .bas.txt file to .bas file        |
| bas2aql.bat | Copies .bas file to AquaLite USB directory |

| File Name       | Description                                |
| --------------- | ---------------------------------          |
| manual_tests.md | List of tests that can not be automated    |
| bas2aql.bat | Copies .bas file to AquaLite USB directory |


## File Extensions

Files with extension .bas.txt are untokenized BASIC programs.

Files with extension .bas are tokenized BASIC programs in CAQ format.

| Basic Program  | Description                           |
| -------------- | ---------------------------------     |
| aqunit.bas.txt | Aquarius Unit Test Framework          |
| aqex.bas.txt   | Example test program using framework  |
| asc.bas.txt    | Test ASC(), ASC$(), DEC()             |
| err.bas.txt    | Test ERROR, ERR(), ERR$()             |
| get.bas.txt    | Test GET, PUT, CLS                    |
| hex.bas.txt    | Test HEX$                             |
| menu.bas.txt   | Test MENU, KEY                        |
| mid.bas.txt    | Test MID$(), STRING\$(),INSTR()       |
| peek.bas.txt   | Test PEEK(), $ and &                  |
| poke.bas.txt   | Test POKE, DOKE, DEEK, COPY           |
| save.bas.txt   | Test SAVE, LOAD, DEL, FILE$, FILEEND  |
| xor.bas.txt    | Test AND(), OR(), XOR()               |

## Converting and running files

To convert file *program.bas.txt* to *program.bas*, use command line:

    txt2bas program

To copy file *program.bas* to the AquaLite USB directory use command line:

    txt2bas program

The program can then be run in aqualite using the command RUN "*program*"

Note: The script bas2aql.bat expects the environment variable %AQUALITE%
to contain the AquaLite program directory and that the subdirectory 
%AQUALITE%\usb\aqunit exists.
