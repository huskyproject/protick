{ $O+,F+,I-,S-,R-,V-}
Unit MKFile;

{$IfDef FPC}
 {$PackRecords 1}
{$EndIf}

Interface

Uses Dos,
{$IFDEF VirtualPascal}
     os2base, os2def, Strings,
{$ENDIF}
{$IFDEF SPEED}
     BseDOS, BseDev,
{$ENDIF}
{$IfDef Linux}
     Linux,
{$EndIf}
     GeneralP;

{ $I FILEMODE.INC}
{--- begin FILEMODE.INC ---}
{$IfDef SPEED}
Uses
  BseDOS;

Const
  fmReadOnly = Open_Access_ReadOnly;
  fmReadWrite = Open_Access_ReadWrite;
  fmDenyNone = Open_Share_DenyNone;

{$Else}

Const
  fmReadOnly = 0;          {FileMode constants}
  fmWriteOnly = 1;
  fmReadWrite = 2;
  fmDenyAll = 16;
  fmDenyWrite = 32;
  fmDenyRead = 48;
  fmDenyNone = 64;
  fmNoInherit = 128;

{$EndIf}
{--- end FILEMODE.INC ---}


Const
  Tries: Word = 150;
  TryDelay: Word = 100;


Type FindRec = Record
  SR: SearchRec;
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
  DError: Word;
  End;


Type FindObj = Object
  FI: ^FindRec;
  Procedure Init; {Initialize}
  Procedure Done; {Done}
  Procedure FFirst(FN: String); {Find first}
  Procedure FNext;
  Function  Found: Boolean; {File was found}
  Function  GetName: String; {Get Filename}
  Function  GetFullPath: String; {Get filename with path}
  Function  GetDate: LongInt; {Get file date}
  Function  GetSize: LongInt; {Get file size}
  End;


Type TFileArray = Array[1..$fff0] of Char;

Type TFileRec = Record
  MsgBuffer: ^TFileArray;
  BufferPtr: Word;
  {$IFDEF VirtualPascal}
  BufferChars: LongInt;
  {$ELSE}
  BufferChars: Word;
  {$ENDIF}
  BufferStart: LongInt;
  BufferFile: File;
  CurrentStr: String;
  StringFound: Boolean;
  Error: Word;
  BufferSize: Word;
  End;


Type TFile = Object
  TF: ^TFileRec;
  Procedure Init;
  Procedure Done;
  Function  GetString:String;          {Get string from file}
  Function  GetUString: String; {Get LF delimited string}
  Function  OpenTextFile(FilePath: String): Boolean;  {Open file}
  Function  CloseTextFile: Boolean;    {Close file}
  Function  GetChar: Char;             {Internal use}
  Procedure BufferRead;                {Internal use}
  Function  StringFound: Boolean;      {Was a string found}
  Function  SeekTextFile(SeekPos: LongInt): Boolean; {Seek to position}
  Function  GetTextPos: LongInt;       {Get text file position}
  Function  Restart: Boolean;          {Reset to start of file}
  Procedure SetBufferSize(BSize: Word); {Set buffer size}
  End;



var
  MKFileError: Word;

function  Exist (fname : string; attr : word) : boolean;
Function  FileExist(FName: String): Boolean;
Function  SizeFile(FName: String): LongInt;
Function  DateFile(FName: String): LongInt;
Function  FindPath(FileName: String): String;
Function  LongLo(InNum: LongInt): Word;
Function  LongHi(InNum: LongInt): Word;
Function  LockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
Function  UnLockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
Function  shAssign(Var F: File; FName: String): Boolean;
Function  shLock(Var F; LockStart,LockLength: LongInt): Word;
Procedure FlushFile(Var F); {Dupe file handle, close dupe handle}
Function  shReset(Var F: File; RecSize: Word): Boolean;
{$IFNDEF VIRTUALPASCAL}
Function  shRead(Var F: File; Var Rec; ReadSize: Word; Var NumRead: Word): Boolean;
Function  shWrite(Var F: File; Var Rec; ReadSize: Word): Boolean;
{$ELSE}
Function  shRead(Var F: File; Var Rec; ReadSize: Word; Var NumRead: LongInt): Boolean;
Function  shWrite(Var F: File; Var Rec; ReadSize: LongInt): Boolean;

{$ENDIF}
Function  shOpenFile(Var F: File; PathName: String): Boolean;
Function  shMakeFile(Var F: File; PathName: String): Boolean;
Procedure shCloseFile(Var F: File);
Function  shSeekFile(Var F: File; FPos: LongInt): Boolean;
Function  shFindFile(Pathname: String; Var Name: String; Var Size, Time: LongInt): Boolean;
Procedure shSetFTime(Var F: File; Time: LongInt);
Function  GetCurrentPath: String;
Procedure CleanDir(FileDir: String);
Function  IsDevice(FilePath: String): Boolean;
Function  LoadFilePos(FN: String; Var Rec; FS: Word; FPos: LongInt): Word;
Function  LoadFile(FN: String; Var Rec; FS: Word): Word;
Function  SaveFilePos(FN: String; Var Rec; FS: Word; FPos: LongInt): Word;
Function  SaveFile(FN: String; Var Rec; FS: Word): Word;
Function  ExtendFile(FN: String; ToSize: LongInt): Word;
Function  CreateTempDir(FN: String): String;
Function  GetTempName(FN: String): String;
Function  GetTextPos(Var F: Text): LongInt;
Function  FindOnPath(FN: String; Var OutName: String): Boolean;
Function  CopyFile(FN1: String; FN2: String): Boolean;
Function  EraseFile(FN: String): Boolean;
Function  MakePath(FP: String): Boolean;


Implementation

{$IfNDef FPC}
Uses Crt;
{$EndIf}


Procedure FindObj.Init;
  Begin
  New(FI);
  FI^.DError := 1;
  End;


Procedure FindObj.Done;
  Begin
  Dispose(FI);
  End;


Procedure FindObj.FFirst(FN: String);
  Begin
  FN := FExpand(FN);
  FSplit(FN, FI^.Dir, FI^.Name, FI^.Ext);
  FindFirst(FN, Archive + ReadOnly, FI^.SR);
  FI^.DError := dos.DosError;
  End;


Function  FindObj.GetName: String;
  Begin
  If Found Then
    Begin
    GetName := FI^.SR.Name
    End
  Else
    GetName := '';
  End;


Function FindObj.GetFullPath: String;
  Begin
  GetFullPath := FI^.Dir + GetName;
  End;


Function  FindObj.GetSize: LongInt;
  Begin
  If Found Then
    GetSize := FI^.SR.Size
  Else
    GetSize := 0;
  End;


Function  FindObj.GetDate: LongInt;
  Begin
  If Found Then
    GetDate := FI^.SR.Time
  Else
    GetDate := 0;
  End;


Procedure FindObj.FNext;
  Begin
  FindNext(FI^.SR);
  FI^.DError := dos.DosError;
  End;


Function FindObj.Found: Boolean;
  Begin
  Found := (FI^.DError = 0);
  End;


Function shAssign(Var F: File; FName: String): Boolean;
  Begin
  Assign(F, FName);
  MKFileError := IoResult;
  shAssign := (MKFileError = 0);
  End;


{$IFNDEF VIRTUALPASCAL}
Function shRead(Var F: File; Var Rec; ReadSize: Word; Var NumRead: Word): Boolean;
{$ELSE}
Function shRead(Var F: File; Var Rec; ReadSize: Word; Var NumRead: LongInt): Boolean;
{$ENDIF}
  Var
    Count: Word;
    Code: Word;
{$IfDef SPEED}
    nr: LongWord;
{$EndIf}

  Begin
  if ioresult<>0 then;
  Count := Tries;
  Code := 5;
  While ((Count > 0) and (Code = 5)) Do Begin
{$IfDef SPEED}
    BlockRead(F,Rec,ReadSize,NR);
    NumRead := NR;
{$Else}
    BlockRead(F,Rec,ReadSize,NumRead);
{$EndIf}
    Code := IoResult;
    Dec(Count);
    End;
  MKFileError := Code;
  ShRead := (Code = 0);
  End;

{$IFNDEF VIRTUALPASCAL}
Function shWrite(Var F: File; Var Rec; ReadSize: Word): Boolean;
{$ELSE}
Function shWrite(Var F: File; Var Rec; ReadSize: LongInt): Boolean;
{$ENDIF}
  Var
    Count: Word;
    Code: Word;

  Begin
  Count := Tries;
  Code := 5;
  While ((Count > 0) and (Code = 5)) Do
    Begin
    BlockWrite(F,Rec,ReadSize);
    Code := IoResult;
    Dec(Count);
    End;
  MKFileError := Code;
  shWrite := (Code = 0);
  End;


Procedure CleanDir(FileDir: String);
  Var
      SR: SearchRec;
    F: File;

  Begin
  FindFirst(FileDir + '*.*', ReadOnly + Archive, SR);
  While dos.DosError = 0 Do
    Begin
    If Not shAssign(F, FileDir + SR.Name) Then;
    Erase(F);
    If IoResult <> 0 Then;
    FindNext(SR);
    End;
  End;



Function GetCurrentPath: String;
  Var
    CName: NameStr;
    Path: DirStr;
    CExt: ExtStr;

  Begin
  FSplit(FExpand('*.*'),Path,CName,CExt);
  GetCurrentPath := Path;
  End;


Function shLock(Var F; LockStart,LockLength: LongInt): Word;
  Var
    Count: Word;
    Code: Word;
    i: Word;

  Begin
  Count := Tries;
  Code := $21;
  While ((Count > 0) and (Code = $21)) Do
    Begin
    Code := LockFile(F,LockStart,LockLength);
    Dec(Count);
    If Code = $21 Then
      Delay(TryDelay);
    End;
  If Code = 1 Then
    Code := 0;
  shLock := Code;
  End;



Function shReset(Var F: File; RecSize: Word): Boolean;
  Var
    Count: Word;
    Code: Word;

  Begin
  Count := Tries;
  Code := 5;
  While ((Count > 0) and (Code = 5)) Do
    Begin
    {$I-} Reset(F,RecSize);
    Code := IoResult;
    Dec(Count);
    End;
  MKFileError := Code;
  ShReset := (Code = 0);
  End;

{$IFDEF OS2}
procedure FlushFile(Var F);
var handle,
    newhandle : LongInt {HFILE};
    rc : APIRET;
begin
  handle := FileRec(F).handle;
  newhandle := HFile(-1);
  if DosDupHandle(handle, newHandle) = 0 then
    rc := DosClose(newHandle);
end;
{$ELSE}
 {$IFDEF FPC}
procedure FlushFile(Var F);
begin
Flush(text(F));
end;
 {$ELSE}
Procedure FlushFile(Var F); {Dupe file handle, close dupe handle}
  Var
    Handle: Word Absolute F;
  {$IFDEF BASMINT}
    Tmp: Word;
  {$ELSE}
    Regs: Registers;
  {$ENDIF}

  Begin
  {$IFDEF BASMINT}
  Tmp := Handle;
  Asm
    Mov ah, $45;
    Mov bx, Tmp;
    Int $21;
    Jc  @JFlush;
    Mov bx, ax;
    Mov ah, $3e;
    Int $21;
    @JFlush:
    End;
  {$ELSE}
  Regs.ah := $45;
  Regs.bx := Handle;
  MsDos(Regs);
  If (Regs.Flags and 1) = 0 Then   {carry}
    Begin
    Regs.bx := Regs.ax;
    Regs.Ah := $3e;
    MsDos(Regs);
    End;
  {$ENDIF}
  End;
 {$EndIf}
{$ENDIF}

{$IFDEF OS2}
function LockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;

var
  lock, unlock : FileLock;

begin
  with lock do
    begin
      lOffset := LockStart;
      lRange := LockLength;
    end;
  with unlock do
    begin
      lOffset := 0;
      lRange := 0;
    end;
  LockFile := DosSetFileLocks(FileRec(F).Handle, unlock, lock, 1000, 0);
end;
{$ELSE}
 {$IfDef Linux}
Function LockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
 Begin
 FLock(file(f), Lock_Ex);
 LockFile := LinuxError;
 End;
 {$Else}

Function LockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
  Var
    Handle: Word Absolute F;
    Tmp: Word;
    StrtHi: Word;
    StrtLo: Word;
    LgHi: Word;
    LgLo: Word;
  {$IFNDEF BASMINT}
    Regs: Registers;
  {$ENDIF}

  Begin
  Tmp := Handle;
  StrtHi := LongHi(LockStart);
  StrtLo := LongLo(LockStart);
  LgHi := LongHi(LockLength);
  LgLo := LongLo(LockLength);
  {$IFDEF BASMINT}
  Asm
    Mov ah, $5c;
    Mov al, $00;
    Mov bx, Tmp;
    Mov cx, StrtHi;
    Mov dx, StrtLo;
    Mov si, LgHi;                 {00h = success           }
    Mov di, LgLo;                 {01h = share not loaded  }
    Int $21;                      {06h = invalid handle    }
    Jc @JLock                     {21h = lock violation    }
    Mov ax, $00;                  {24h = share buffer full }
    @JLock:
    Mov Tmp, ax;
    End;
  {$ELSE}
  Regs.ah := $5c;
  Regs.al := $00;
  Regs.bx := Tmp;
  Regs.cx := StrtHi;
  Regs.dx := StrtLo;
  Regs.si := LgHi;
  Regs.di := LgLo;
  MsDos(Regs);
  If (Regs.Flags and 1) = 0 Then
    Begin
    Regs.ax := 0;
    End;
  Tmp := Regs.ax;
  {$ENDIF}
  If Tmp = 1 Then
    Tmp := 0;
  LockFile := Tmp;
  End;
 {$EndIf}
{$ENDIF}

{$IFDEF OS2}
function UnLockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;

var
  lock, unlock : FileLock;

begin
  with unlock do
    begin
      lOffset := LockStart;
      lRange := LockLength;
    end;
  with lock do
    begin
      lOffset := 0;
      lRange := 0;
    end;
  UnLockFile := DosSetFileLocks(FileRec(F).Handle, unlock, lock, 1000, 0);
end;

{$ELSE}
 {$IfDef Linux}
Function UnLockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
 Begin
 FLock(file(f), Lock_Un);
 UnLockFile := LinuxError;
 End;
 {$Else}

Function UnLockFile(Var F; LockStart: LongInt; LockLength: LongInt): Word;
  Var
    Handle: Word Absolute F;
    Tmp: Word;
    StrtHi: Word;
    StrtLo: Word;
    LgHi: Word;
    LgLo: Word;
  {$IFNDEF BASMINT}
    Regs: Registers;
  {$ENDIF}

  Begin
  Tmp := Handle;
  StrtHi := LongHi(LockStart);
  StrtLo := LongLo(LockStart);
  LgHi := LongHi(LockLength);
  LgLo := LongLo(LockLength);
  {$IFDEF BASMINT}
  Asm
    Mov ah, $5c;
    Mov al, $01;
    Mov bx, Tmp;
    Mov cx, StrtHi;
    Mov dx, StrtLo;
    Mov si, LgHi;                 {00h = success           }
    Mov di, LgLo;                 {01h = share not loaded  }
    Int $21;                      {06h = invalid handle    }
    Jc @JLock                     {21h = lock violation    }
    Mov ax, $00;                  {24h = share buffer full }
    @JLock:
    Mov Tmp, ax;
    End;
  {$ELSE}
  Regs.ah := $5c;
  Regs.al := $01;
  Regs.bx := Tmp;
  Regs.cx := StrtHi;
  Regs.dx := StrtLo;
  Regs.si := LgHi;
  Regs.di := LgLo;
  MsDos(Regs);
  If (Regs.Flags and 1) = 0 Then
    Begin
    Regs.ax := 0;
    End;
  Tmp := Regs.ax;
  {$ENDIF}
  If Tmp = 1 Then
    Tmp := 0;
  UnLockFile := Tmp;
  End;
 {$EndIf}
{$ENDIF}


Function LongLo(InNum: LongInt): Word;
  Begin
  LongLo := InNum and $FFFF;
  End;


Function LongHi(InNum: LongInt): Word;
  Begin
  LongHi := InNum Shr 16;
  End;


Function SizeFile(FName: String): LongInt;
  Var
    SR: SearchRec;

  Begin
  FindFirst(FName, AnyFile, SR);
  If dos.DosError = 0 Then
    SizeFile := SR.Size
  Else
    SizeFile := -1;
  End;


Function  DateFile(FName: String): LongInt;
  Var
    SR: SearchRec;

  Begin
  FindFirst(FName, AnyFile, SR);
  If dos.DosError = 0 Then
    DateFile := SR.Time
  Else
    DateFile := 0;
  End;


function exist (fname : string; attr : word) : boolean;
var
  sr : SearchRec;
begin
  FindFirst (fname, attr, sr);
  exist := (dos.DosError = 0);
  {$IFDEF OS2}
  FindClose(sr);
  {$ENDIF}
end;

function FileExist(FName: String): Boolean;
var
  SR: SearchRec;
begin
  FindFirst(FName, ReadOnly + Hidden + Archive + directory, SR);
  FileExist:=(dos.DosError = 0);
  {$IFDEF OS2}
  FindClose(SR);
  {$ENDIF}
end;


Function FindPath(FileName: String):String;
  Begin
  FindPath := FileName;
  If FileExist(FileName) Then
    FindPath := FExpand(FileName)
  Else
    FindPath := FExpand(FSearch(FileName,DOS.GetEnv('PATH')));
  End;


Procedure TFile.BufferRead;
  Begin
  TF^.BufferStart := FilePos(TF^.BufferFile);
  if Not shRead (TF^.BufferFile,TF^.MsgBuffer^ , TF^.BufferSize, TF^.BufferChars) Then
    TF^.BufferChars := 0;
  TF^.BufferPtr := 1;
  End;


Function TFile.GetChar: Char;
  Begin
  If TF^.BufferPtr > TF^.BufferChars Then
    BufferRead;
  If TF^.BufferChars > 0 Then
    GetChar := TF^.MsgBuffer^[TF^.BufferPtr]
  Else
    GetChar := #0;
  Inc(TF^.BufferPtr);
  If TF^.BufferPtr > TF^.BufferChars Then
    BufferRead;
  End;


Function TFile.GetString: String;

  Var
    TempStr: String;
    GDone: Boolean;
    Ch: Char;

  Begin
    TempStr := '';
    GDone := False;
    TF^.StringFound := False;
    While Not GDone Do
      Begin
      Ch := GetChar;
      Case Ch Of
        #0:  If TF^.BufferChars = 0 Then
               GDone := True
             Else
               Begin
               Inc(byte(TempStr[0]));
               TempStr[Ord(TempStr[0])] := Ch;
               TF^.StringFound := True;
               If Length(TempStr) = 255 Then
                 GDone := True;
               End;
        #10:;
        #26:;
        #13: Begin
             GDone := True;
             TF^.StringFound := True;
             End;
        Else
          Begin
            Inc(byte(TempStr[0]));
            TempStr[Ord(TempStr[0])] := Ch;
            TF^.StringFound := True;
            If Length(TempStr) = 255 Then
              GDone := True;
          End;
        End;
      End;
    GetString := TempStr;
  End;


Function TFile.GetUString: String;

  Var
    TempStr: String;
    GDone: Boolean;
    Ch: Char;

  Begin
  TempStr := '';
  GDone := False;
  TF^.StringFound := False;
  While Not GDone Do
    Begin
    Ch := GetChar;
    Case Ch Of
      #0:  If TF^.BufferChars = 0 Then
             GDone := True
           Else
             Begin
             Inc(byte(TempStr[0]));
             TempStr[Ord(TempStr[0])] := Ch;
             TF^.StringFound := True;
             If Length(TempStr) = 255 Then
               GDone := True;
             End;
      #13:;
      #26:;
      #10: Begin
           GDone := True;
           TF^.StringFound := True;
           End;
      Else
        Begin
        Inc(byte(TempStr[0]));
        TempStr[Ord(TempStr[0])] := Ch;
        TF^.StringFound := True;
        If Length(TempStr) = 255 Then
          GDone := True;
        End;
      End;
    End;
  GetUString := TempStr;
  End;


Function TFile.OpenTextFile(FilePath: String): Boolean;
  Begin
  If Not shAssign(TF^.BufferFile, FilePath) Then;
  FileMode := fmReadOnly + fmDenyNone;
  If Not shReset(TF^.BufferFile,1) Then
    OpenTextFile := False
  Else
    Begin
    BufferRead;
    If TF^.BufferChars > 0 Then
      TF^.StringFound := True
    Else
      TF^.StringFound := False;
    OpenTextFile := True;
    End;
  End;


Function TFile.SeekTextFile(SeekPos: LongInt): Boolean;
  Begin
  TF^.Error := 0;
  If ((SeekPos < TF^.BufferStart) Or (SeekPos > TF^.BufferStart + TF^.BufferChars)) Then
    Begin
    Seek(TF^.BufferFile, SeekPos);
    TF^.Error := IoResult;
    BufferRead;
    End
  Else
    Begin
    TF^.BufferPtr := SeekPos + 1 - TF^.BufferStart;
    End;
  SeekTextFile := (TF^.Error = 0);
  End;


Function TFile.GetTextPos: LongInt;       {Get text file position}
  Begin
  GetTextPos := TF^.BufferStart + TF^.BufferPtr - 1;
  End;


Function TFile.Restart: Boolean;
  Begin
  Restart := SeekTextFile(0);
  End;


Function TFile.CloseTextFile: Boolean;
  Begin
  Close(TF^.BufferFile);
  CloseTextFile := (IoResult = 0);
  End;


Procedure TFile.SetBufferSize(BSize: Word);
  Begin
  FreeMem(TF^.MsgBuffer, TF^.BufferSize);
  TF^.BufferSize := BSize;
  GetMem(TF^.MsgBuffer, TF^.BufferSize);
  TF^.BufferChars := 0;
  TF^.BufferStart := 0;
  If SeekTextFile(GetTextPos) Then;
  End;


Procedure TFile.Init;
  Begin
  New(TF);
  TF^.BufferSize := 2048;
  GetMem(TF^.MsgBuffer, TF^.BufferSize);
  End;


Procedure TFile.Done;
  Begin
  Close(TF^.BufferFile);
  If IoResult <> 0 Then;
  FreeMem(TF^.MsgBuffer, TF^.BufferSize);
  Dispose(TF);
  End;


Function TFile.StringFound: Boolean;
  Begin
  StringFound := TF^.StringFound;
  End;


Function  shOpenFile(Var F: File; PathName: String): Boolean;
  Begin
  Assign(f,pathname);
  FileMode := fmReadWrite + fmDenyNone;
  shOpenFile := shReset(f,1);
  End;


Function  shMakeFile(Var F: File; PathName: String): Boolean;
  Begin
  Assign(f,pathname);
  {$I-} ReWrite(f,1);
  shMakeFile := (IOresult = 0);
  END;


Procedure shCloseFile(Var F: File);
  Begin
  Close(F);
  If (IOresult <> 0) Then;
  End;


Function  shSeekFile(Var F: File; FPos: LongInt): Boolean;
  Begin
  Seek(F,FPos);
  shSeekFile := (IOresult = 0);
  End;


Function  shFindFile(Pathname: String; Var Name: String; Var Size, Time: LongInt): Boolean;
  Var
      SR: SearchRec;

  Begin
  FindFirst(PathName, Archive, SR);
  If (dos.DosError = 0) Then
    Begin
    shFindFile := True;
    Name := Sr.Name;
    Size := Sr.Size;
    Time := Sr.Time;
    End
  Else
    Begin
    shFindFile := False;
    End;
  End;


Procedure shSetFTime(Var F: File; Time: LongInt);
  Begin
  SetFTime(F, Time);
  If (IOresult <> 0) Then;
  End;

{$IFDEF OS2}
function IsDevice(FilePath: String): Boolean;
begin
  runerror(211);
end;
{$ELSE}
 {$IFDEF FPC}
function IsDevice(FilePath: String): Boolean;
Var
 info: Stat;

begin
FStat(FilePath, info);
IsDevice := not S_ISREG(info.mode);
end;

 {$ELSE}
Function IsDevice(FilePath: String): Boolean;
  Var
    F: File;
    Handle: Word Absolute F;
    Tmp: Word;
  {$IFNDEF BASMINT}
    Regs: Registers;
  {$ENDIF}

  Begin
  Assign(F, FilePath);
  {$I-} Reset(F);
  If IoResult <> 0 Then
    IsDevice := False
  Else
    Begin
    Tmp := Handle;
{$IFDEF BASMINT}
    Asm
      Mov ah, $44;
      Mov al, $00;
      Mov bx, Tmp;
      Int $21;
      Or  dx, $80;
      Je  @JDev;
      Mov ax, $01;
      @JDev:
      Mov ax, $00;
      Mov @Result, al;
      End;
{$ELSE}
    Regs.ah := $44;
    Regs.al := $00;
    Regs.bx := Tmp;
    MsDos(Regs);
    IsDevice := (Regs.Dx and $80) <> 0;
{$ENDIF}
    End;
  Close(F);
  If IoResult <> 0 Then;
  End;
 {$EndIf}
{$ENDIF}


Function LoadFile(FN: String; Var Rec; FS: Word): Word;
  Begin
  LoadFile := LoadFilePos(FN, Rec, FS, 0);
  End;


Function LoadFilePos(FN: String; Var Rec; FS: Word; FPos: LongInt): Word;
  Var
    F: File;
    Error: Word;
    {$IFDEF VirtualPascal}
    NumRead: LongInt;
    {$ELSE}
    NumRead: Word;
    {$ENDIF}
  Begin
  Error := 0;
  If Not FileExist(FN) Then
    Error := 8888;
  If Error = 0 Then
    Begin
    If Not shAssign(F, FN) Then
      Error := MKFileError;
    End;
  FileMode := fmReadOnly + fmDenyNone;
  If Not shReset(F,1) Then
    Error := MKFileError;
  If Error = 0 Then
    Begin
    Seek(F, FPos);
    Error := IoResult;
    End;
  If Error = 0 Then
    If Not shRead(F, Rec, FS, NumRead) Then
      Error := MKFileError;
  If Error = 0 Then
    Begin
    Close(F);
    Error := IoResult;
    End;
  LoadFilePos := Error;
  End;


Function SaveFile(FN: String; Var Rec; FS: Word): Word;
   Begin
   SaveFile := SaveFilePos(FN, Rec, FS, 0);
   End;



Function SaveFilePos(FN: String; Var Rec; FS: Word; FPos: LongInt): Word;
  Var
    F: File;
    Error: Word;

  Begin
  Error := 0;
  If Not shAssign(F, FN) Then
    Error := MKFileError;
  FileMode := fmReadWrite + fmDenyNone;
  If FileExist(FN) Then
    Begin
    If Not shReset(F,1) Then
      Error := MKFileError;
    End
  Else
    Begin
    {$I-} ReWrite(F,1);
    Error := IoResult;
    End;
  If Error = 0 Then
    Begin
    Seek(F, FPos);
    Error := IoResult;
    End;
  If Error = 0 Then
    If FS > 0 Then
      Begin
      If Not shWrite(F, Rec, FS) Then
        Error := MKFileError;
      End;
  If Error = 0 Then
    Begin
    Close(F);
    Error := IoResult;
    End;
  SaveFilePos := Error;
  End;


Function ExtendFile(FN: String; ToSize: LongInt): Word;
{Pads file with nulls to specified size}
  Type
    FillType = Array[1..8000] of Byte;

  Var
    F: File;
    Error: Word;
    FillRec: ^FillType;

  Begin
  Error := 0;
  New(FillRec);
  If FillRec = Nil Then
    Error := 10;
  If Error = 0 Then
    Begin
    FillChar(FillRec^, SizeOf(FillRec^), 0);
    If Not shAssign(F, FN) Then
    Error := MKFileError;
    FileMode := fmReadWrite + fmDenyNone;
    If FileExist(FN) Then
      Begin
      If Not shReset(F,1) Then
        Error := MKFileError;
      End
    Else
      Begin
      {$I-} ReWrite(F,1);
      Error := IoResult;
      End;
    End;
  If Error = 0 Then
    Begin
    Seek(F, FileSize(F));
    Error := IoResult;
    End;
  If Error = 0 Then
    Begin
    While ((FileSize(F) < (ToSize - SizeOf(FillRec^))) and (Error = 0)) Do
      Begin
      If Not shWrite(F, FillRec^, SizeOf(FillRec^)) Then
        Error := MKFileError;
      End;
    End;
  If ((Error = 0) and (FileSize(F) < ToSize)) Then
    Begin
    If Not shWrite(F, FillRec^, ToSize - FileSize(F)) Then
      Error := MKFileError;
    End;
  If Error = 0 Then
    Begin
    Close(F);
    Error := IoResult;
    End;
  Dispose(FillRec);
  ExtendFile := Error;
  End;

{$IFDEF OS2}
function CreateTempDir(FN: String): String;

begin
  runerror(211);
end;
{$ELSE}
 {$IfDef FPC}
function CreateTempDir(FN: String): String;

begin
end;
 {$Else}
Function  CreateTempDir(FN: String): String;
  Var
    TOfs: Word;
    TSeg: Word;
    FH: Word;
    i: Word;
    TmpStr: String;

  Begin
  TSeg := Seg(TmpStr[1]);
  TOfs := Ofs(TmpStr[1]);
  If ((Length(FN) > 0) and (FN[Length(FN)] <> DirSep)) Then
    TmpStr := FN + DirSep
  Else
    TmpStr := FN;
  For i := 1 to 16 Do
   TmpStr[Length(TmpStr) + i] := #0;
  i := 0;
  Asm
    Mov bx, TSeg;
    Mov ax, TOfs;
    Push ds;
    Mov ds, bx;
    Mov dx, ax;
    Mov ah, $5a;
    Mov ch, $00;
    ; {Mov dx, TSeg;}
    ; {Mov ds, dx;}
    ; {Mov dx, TOfs;}
    Mov cl, $00;
    Int $21;              {Create tmp file}
    Mov FH, ax;
    Mov ax, 1;
    jc @JErr
    Mov bx, FH;
    Mov ah, $3e;
    jmp @J3;
    Int $21;              {Close tmp file}
    @J3:
    Mov ax, 2;
    jc @JErr;
    Mov ah, $41
    Mov dx, TSeg;
    Mov ds, dx;
    Mov dx, TOfs;
    Int $21;              {Erase tmp file}
    Mov ax, 3;
    jc @JErr;
    Mov ah, $39;
    Mov dx, TSeg;
    Mov ds, dx;
    Mov dx, TOfs;
    Int $21;              {Create directory}
    Mov ax, 4;
    jc @JErr;
    Jmp @JEnd;
    @JErr:
    Mov i, ax;
    @JEnd:
    Pop ds;
    End;
  TmpStr[0] := #255;
  TmpStr[0] := Chr(Pos(#0, TmpStr) - 1);
  If i = 0 Then
    CreateTempDir := TmpStr
  Else
    CreateTempDir := '';
  End;
 {$EndIf}
{$ENDIF}

{$IFDEF OS2}
function GetTempName(FN: String): String;

var
  TmpStr,
  tmp : string;
  nr : LongInt;

begin
  If ((Length(FN) > 0) and (FN[Length(FN)] <> DirSep)) Then
    TmpStr := FN + DirSep
  Else
    TmpStr := FN;
  nr := 0;
  repeat
  inc(nr);
  str(nr, tmp);
  until (nr = 1000) or not (fileexist(tmpstr+tmp));
  if nr <> 1000 then GetTempName := tmpstr+tmp else gettempname := '';
end;

{$ELSE}
 {$IfDef FPC}
function GetTempName(FN: String): String;

var
  TmpStr,
  tmp : string;
  nr : LongInt;

begin
  If ((Length(FN) > 0) and (FN[Length(FN)] <> DirSep)) Then
    TmpStr := FN + DirSep
  Else
    TmpStr := FN;
  nr := 0;
  repeat
  inc(nr);
  str(nr, tmp);
  until (nr = 1000) or not (fileexist(tmpstr+tmp));
  if nr <> 1000 then GetTempName := tmpstr+tmp else gettempname := '';
end;
{$Else}

Function  GetTempName(FN: String): String;
  Var
    TOfs: Word;
    TSeg: Word;
    FH: Word;
    i: Word;
    TmpStr: String;

  Begin
  TSeg := Seg(TmpStr[1]);
  TOfs := Ofs(TmpStr[1]);
  If ((Length(FN) > 0) and (FN[Length(FN)] <> DirSep)) Then
    TmpStr := FN + DirSep
  Else
    TmpStr := FN;
  For i := 1 to 16 Do
   TmpStr[Length(TmpStr) + i] := #0;
  i := 0;
  Asm
    Push ds;
    Mov ah, $5a;
    Mov ch, $00;
    Mov dx, TSeg;
    Mov ds, dx;
    Mov dx, TOfs;
    Mov cl, $00;
    Int $21;              {Create tmp file}
    Mov FH, ax;
    Mov ax, 1;
    jc @JErr
    Mov bx, FH;
    Mov ah, $3e;
    {jmp @J3; this was originally in my code, appears to be an error}
    Int $21;              {Close tmp file}
    @J3:
    Mov ax, 2;
    jc @JErr;
    Mov ah, $41
    Mov dx, TSeg;
    Mov ds, dx;
    Mov dx, TOfs;
    Int $21;              {Erase tmp file}
    Mov ax, 3;
    jc @JErr;
    jmp @JEnd
    @JErr:
    Mov i, ax;
    @JEnd:
    Pop ds;
    End;
  TmpStr[0] := #255;
  TmpStr[0] := Chr(Pos(#0, TmpStr) - 1);
  If i = 0 Then
    GetTempName := TmpStr
  Else
    GetTempName := '';
  End;
 {$EndIf}
{$ENDIF}

{$IFDEF OS2}
function gettextpos(var f:text): LongInt;
begin
  runerror(211);
end;
{$ELSE}
 {$IfDef FPC}
function gettextpos(var f:text): LongInt;
begin
end;
{$Else}
Function  GetTextPos(Var F: Text): LongInt;
  Type WordRec = Record
    LongLo: Word;
    LongHi: Word;
    End;

  Var
   TR: TextRec Absolute F;
   Tmp: LongInt;
   Handle: Word;
   {$IFNDEF BASMINT}
     Regs: Registers;
   {$ENDIF}

  Begin
  Handle := TR.Handle;
  {$IFDEF BASMINT}
  Asm
    Mov ah, $42;
    Mov al, $01;
    Mov bx, Handle;
    Mov cx, 0;
    Mov dx, 0;
    Int $21;
    Jnc @TP2;
    Mov ax, $ffff;
    Mov dx, $ffff;
    @TP2:
    Mov WordRec(Tmp).LongLo, ax;
    Mov WordRec(Tmp).LongHi, dx;
    End;
  {$ELSE}
  Regs.ah := $42;
  Regs.al := $01;
  Regs.bx := Handle;
  Regs.cx := 0;
  Regs.dx := 0;
  MsDos(Regs);
  If (Regs.Flags and 1) <> 0 Then
    Begin
    Regs.ax := $ffff;
    Regs.dx := $ffff;
    End;
  WordRec(Tmp).LongLo := Regs.Ax;
  WordRec(Tmp).LongHi := Regs.Dx;
  {$ENDIF}
  If Tmp >= 0 Then
    Inc(Tmp, TR.BufPos);
  GetTextPos := Tmp;
  End;
 {$EndIf}
{$ENDIF}


Function FindOnPath(FN: String; Var OutName: String): Boolean;
  Var
    TmpStr: String;

  Begin
  If FileExist(FN) Then
    Begin
    OutName := FExpand(FN);
    FindOnPath := True;
    End
  Else
    Begin
    TmpStr := FSearch(FN, DOS.GetEnv('Path'));
    If FileExist(TmpStr) Then
      Begin
      OutName := TmpStr;
      FindOnPath := True;
      End
    Else
      Begin
      OutName := FN;
      FindOnPath := False;
      End;
    End;
  End;


Function  CopyFile(FN1: String; FN2: String): Boolean;
  Type
    TmpBufType = Array[1..8192] of Byte;

  Var
    F1: File;
    F2: File;
    {$IFDEF VirtualPascal}
    NumRead: LongInt;
    {$ELSE}
      {$IfDef SPEED}
      NumRead: LongWord;
      {$Else}
      NumRead: Word;
      {$EndIf}
    {$ENDIF}
    Buf: ^TmpBufType;
    Error: Word;

  Begin
  New(Buf);
  Error := 0;
  Assign(F1, FN1);
  FileMode := fmReadOnly + fmDenyNone;
  {$I-} Reset(F1, 1);
  Error := IoResult;
  If Error = 0 Then
    Begin
    Assign(F2, FN2);
    FileMode := fmReadWrite + fmDenyNone;
    {$I-} ReWrite(F2, 1);
    Error := IoResult;
    End;
  If Error = 0 Then
    Begin
    BlockRead(F1, Buf^, SizeOf(Buf^), NumRead);
    Error := IoResult;
    While ((NumRead <> 0) and (Error = 0)) Do
      Begin
      BlockWrite(F2, Buf^, NumRead);
      Error := IoResult;
      If Error = 0 Then
        Begin
        BlockRead(F1, Buf^, SizeOf(Buf^), NumRead);
        Error := IoResult;
        End;
      End;
    End;
  If Error = 0 Then
    Begin
    Close(F1);
    Error := IoResult;
    End;
  If Error = 0 Then
    Begin
    Close(F2);
    Error := IoResult;
    End;
  Dispose(Buf);
  CopyFile := (Error = 0);
  End;


Function  EraseFile(FN: String): Boolean;
  Var
    F: File;

  Begin
  Assign(F, FN);
  Erase(F);
  EraseFile := (IoResult = 0);
  End;


Function  MakePath(FP: String): Boolean;
  Var
    i: Word;

  Begin
  If FP[Length(FP)] <> DirSep Then
    FP := FP + DirSep;
  If Not FileExist(FP + 'Nul') Then
    Begin
    i := 2;
    While (i <= Length(FP)) Do
      Begin
      If FP[i] = DirSep Then
        Begin
        If FP[i-1] <> ':' Then
          Begin
          MkDir(Copy(FP, 1, i - 1));
          If IoResult <> 0 Then;
          End;
        End;
      Inc(i);
      End;
    End;
  MakePath := FileExist(FP + 'Nul');
  End;


End.