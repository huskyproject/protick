Program GenKey;
Uses
  Types, GeneralP, CRC,
  TickType,
  PTRegKey;

Type
 TRegArray = Array[1..SizeOf(TRegInfo)] of Byte;

Var
  f: File of TRegInfo;
  s: String;
  i: Integer;
  p: ^TRegArray;

Procedure Crypt(var Key: TRegInfo);
Var
  p1, p2: ^Byte;
  i: ULong;
  NewKey: TRegInfo;
  s1, s2: String;

 Begin
 p1 := @Key;  p2 := @NewKey;
 s1[0] := #255; s2[0] := #255;
 For i := 1 to 255 do Begin s1[i] := #0; s2[i] := #0; End;

 {calculate CRC, exclude CRCs}
 For i := 1 to SizeOf(TRegInfo)-8 do
  Begin
  p2^ := byte(P1^ XOR (55+i));
  s1[i] := char(p1^); s2[i] := char(p2^);
{$IfDef FPC}
  Inc(ULong(P1)); Inc(ULong(P2));
{$Else}
  Inc(P1); Inc(P2);
{$EndIf}
  End;
 NewKey.DeCryptCRC := CalcCRC(s1); NewKey.CryptCRC := CalcCRC(s2);
 Key := NewKey;
 End;


Begin
Randomize;
If (RegInfo.Ver <> 0) then
  Begin
  Write('Key already exists. Overwrite? ');
  ReadLn(s);
  If (Pos('Y', UpStr(s)) = 0) then Halt(1);
  WriteLn;
  End;
p := @RegInfo;
For i := 1 to SizeOf(RegInfo) do p^[i] := Random(256);
Write('Name: ');
ReadLn(RegInfo.Name);
Write('Addr: ');
ReadLn(s);
Str2Addr(s, RegInfo.Addr);
Write('Serial #: ');
ReadLn(s);
Val(s, RegInfo.Serial, i);
Write('Version (1=noncommercial, 2=commercial, 3=author): ');
ReadLn(s);
Val(s, RegInfo.Ver, i);
Write('Copies: ');
ReadLn(s);
Val(s, RegInfo.Copies, i);
Crypt(RegInfo);
Assign(f, 'protick.key');
{$I-} ReWrite(f); {$I+}
If (IOResult <> 0) then
  Begin
  WriteLn('Couldn''t create protick.key!');
  Halt(3);
  End;
{$I-} Write(f, RegInfo); {$I+}
If (IOResult <> 0) then
  Begin
  WriteLn('Couldn''t write to protick.key!');
  {$I-} Close(f); {$I+}
  If (IOResult <> 0) then WriteLn('Couldn''t close protick.key!');
  Halt(4);
  End;
{$I-} Close(f); {$I+}
If (IOResult <> 0) then
 Begin
 WriteLn('Couldn''t close protick.key!');
 Halt(5);
 End;
{$IfDef Linux}
ChMod('protick.key', 288);
{$EndIf}
WriteLn;
RegInfo := EvalKey;
GetKey;
WriteLn('GetKey report:');
WriteLn('Name:     ', RegInfo.Name);
WriteLn('Addr:     ', Addr2Str(RegInfo.Addr));
WriteLn('Serial #: ', RegInfo.Serial);
WriteLn('Version:  ', RegInfo.Ver);
WriteLn('Copies:   ', RegInfo.Copies);
WriteLn;
WriteLn('<Enter>');
ReadLn;
End.
