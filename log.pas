Unit Log; {In LogDateien schreiben}
Interface

Type
 PLog = ^TLog;
 TLog =
  object
  Constructor Init(LogName : String; _Banner : String; Perm: Word);
  Destructor Done;

  Procedure WriteLn(ToWrite: String);
  Procedure SetCurLevel(NewLevel : Byte);
  Procedure SetLogLevel(NewLevel : Byte);
  Procedure SetScrLevel(NewLevel : Byte);

  Private
  
  F: Text;
  FName: String;
  ProgId: String[8];
  Banner: String[80];
  FilePerm: Word;
  CurLevel: Byte;
  LogLevel: Byte;
  ScrLevel: Byte;
  End;

 

Implementation

Uses
{$IfDef Linux}
 Linux,
{$EndIf}
 DOS;

Const
 BinkChars: Array[1..5] of char = '!+:# ';
 MonthNames: Array[1..12] of String[3] =
  ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
  'Nov', 'Dec');
 DayNames: Array[0..6] of String[3] =
  ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

Type
 TimeTyp =
  Record
  Year, Month, Day, DayOfWeek: Word;
  Hour, Min, Sec, Sec100: Word;
  End;


{$IfDef VIRTUALPASCAL}
Procedure Today(Var Date: TimeTyp);
Var
 Y, M, D, DOW: LongInt;
 
 Begin
 GetDate(Y, M, D, DOW);
 Date.Year := Y;
 Date.Month := M;
 Date.Day := D;
 Date.DayOfWeek := DOW;
 End;

{$Else}
Procedure Today(Var Date : TimeTyp);
 Begin
 With Date do DOS.GetDate(Year, Month, Day, DayOfWeek);
 End;
{$EndIf}

{$IfDef VIRTUALPASCAL}
Procedure Now(Var Time: TimeTyp);
Var
 H, M, S, S100: LongInt;

 Begin
 GetTime(H, M, S, S100);
 Date.Hour := H;
 Date.Min := M;
 Date.Sec := S;
 Date.Sec100 := S100;
 End;

{$Else}
Procedure Now(Var Time: TimeTyp);
 Begin
 With Time do DOS.GetTime(Hour, Min, Sec, Sec100);
 End;
{$EndIf}

Function Date2BinkStr(Date: TimeTyp) : String;
Var
 s: String[10];
 
 Begin
 Str(Date.Day, s);
 If (Length(s) = 1) then s := '0' + s;
 Date2BinkStr:= s + ' ' + MonthNames[Date.Month];
 End;

Function Time2Str(Time:TimeTyp) : String;
var s,s2:String[10];
begin
Str(Time.Hour,s2);
If (Byte(s2[0]) = 1) then s2 := '0' + s2;
s:=s2+':';
Str(Time.Min,s2);
If (Byte(s2[0]) = 1) then s2 := '0' + s2;
s:=s+s2+':';
Str(Time.Sec,s2);
If (Byte(s2[0]) = 1) then s2 := '0' + s2;
Time2Str:=s+s2;
end;


Constructor TLog.Init(LogName : String; _Banner : String; Perm: Word);
 Begin
 Assign(F, LogName);
 {$I-} Append(F); {$I+}
 If (IOResult <> 0) then
  Begin
  Assign(F, LogName);
  {$I-} ReWrite(F); {$I+}
  End;
 If (IOResult = 0) then
  Begin
  FName := LogName;
  Banner := _Banner;
  FilePerm := Perm;
  ProgID := 'PROTICK';
  LogLevel := 5;
  CurLevel := 2;
  ScrLevel := 0;
  TLog.WriteLn('begin, ' + Banner);
  End
 Else Fail;
end;

Destructor TLog.Done;
 Begin
 CurLevel := 2;
 TLog.WriteLn('end, ' + Banner + #10#10);
 {$I-} Close(F); {$I+}
 If (IOResult <> 0) then System.WriteLn('Cannot close logfile!')
 Else
  Begin
{$IfDef Linux}
  ChMod(FName, FilePerm);
{$EndIf}
  End;
 End;

Procedure TLog.WriteLn(ToWrite : String);
Var
  Error: Integer;
  Date: TimeTyp;

 Begin
 Now(Date);
 Today(Date);
 If (ScrLevel >= CurLevel) then System.WriteLn(BinkChars[CurLevel], ' ',
  Date2BinkStr(Date), ' ', Time2Str(Date), ' ', ProgID, ' ', ToWrite);
 If (LogLevel >= CurLevel) then {$I-} System.WriteLn(F, BinkChars[CurLevel], ' ',
  Date2BinkStr(Date), ' ', Time2Str(Date), ' ', ProgID, ' ', ToWrite); {$I+}
 Error := IOResult;
 End;

Procedure TLog.SetCurLevel(NewLevel : Byte);
 Begin
 CurLevel := NewLevel;
 End;

Procedure TLog.SetLogLevel(NewLevel : Byte);
 Begin
 LogLevel := NewLevel;
 End;

Procedure TLog.SetScrLevel(NewLevel : Byte);
 Begin
 ScrLevel := NewLevel;
 End;


Begin
End.
