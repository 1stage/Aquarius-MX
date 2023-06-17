# Manual Tests

## While in aqunit directory

| Command            | Expected Result              |
| ------------------ | ---------------------------- |
| LOAD "testfile.caq | IO Error "filetype mismatch" |
| LOAD "testfile.raw | IO Error "filetype mismatch" |
| LOAD "testfile.txt | IO Error "filetype mismatch" |
| RUN "testfile.caq  | IO Error "filetype mismatch" |
| RUN "testfile.raw  | IO Error "filetype mismatch" |
| RUN "testfile.txt  | IO Error "filetype mismatch" |

## With no USB drive inserted

| Command       | Expected Result  |
| ------------- | ---------------- |
| CAT           | IO Error "???"   |
| CD            | IO Error "???"   |
| DEL "file     | IO Error "???"   |
| DIR           | IO Error "???"   |
| LOAD "file    | IO Error "???"   |
| MKDIR "newdir | IO Error "???"   |
| PRINT CD$     | IO Error "???"   |
| RUN "file     | IO Error "???"   |
| SAVE "file    | IO Error "???"   |
