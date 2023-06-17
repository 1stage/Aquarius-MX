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

| Command       | Expected Result    |
| ------------- | ------------------ |
| CAT           | IO Error "no disk" |
| CD            | IO Error "no disk" |
| DEL "file     | IO Error "no disk" |
| DIR           | IO Error "no disk" |
| LOAD "file    | IO Error "no disk" |
| MKDIR "newdir | IO Error "no disk" |
| PRINT CD$     | IO Error "no disk" |
| RUN "file     | IO Error "no disk" |
| SAVE "file    | IO Error "no disk" |
