/* launch lzh for several files, return errorlevel */
/* syntax: DoLZH <Archive> <ListFile> */

call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
call SysLoadFuncs

parse Arg Archive ' ' ListFile

Result = 0;
do while (Lines(ListFile) > 0)
  CurFile = LineIn(ListFile);
  'LH32 a 'Archive' 'CurFile
  Result = rc;
  If (Result <> 0) then Leave;
  end;
If (Result <> 0) then Say 'Error 'Result' running "LH32 a 'Archive' 'CurFile'"!';
Exit Result

