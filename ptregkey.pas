Unit PTRegKey;
Interface
{$IfDef FPC}
 {$PackRecords 1}
{$EndIf}

Uses
  Types, TickType, DOS, CRC;

Type
     TRegInfo =
       Record
       Name: String80;                    { 81b}
       Addr: TNetAddr;                    { 21b}
       Serial: ULong;                     {  4b}
       Ver: Byte;                         {  1b}
                 {0 evaluation
                  1 noncommercial
                  2 commercial
                  3 author
                  4 invalid}
       Copies: ULong; {0=unlimited}       {  4b}
       CryptCRC: ULong;                   {  4b}
       DeCryptCRC: ULong;                 {  4b}
       End;                               {119b}

Const
  Reg_MaxVersion = 4;
  InvalidKey: TRegInfo =
    (Name:'Invalid Key'; Addr:(Zone:0; Net:0; Node:0; Point:0; Domain:'');
      Serial:0; Ver:4; Copies:0; CryptCRC:0; DeCryptCRC:0);
  EvalKey: TRegInfo =
    (Name:'UNREGISTERED'; Addr:(Zone:0; Net:0; Node:0; Point:0; Domain:'');
      Serial:0; Ver:0; Copies:0; CryptCRC:0; DeCryptCRC:0);

Var
  RegInfo: TRegInfo;

Procedure GetKey;

Implementation

Function ConvWord(w: Word): Word;
 Begin
{$IfDef BigEndian}
 ConvWord := (w mod 256)*256 + (w SHR 8);
{$Else}
 ConvWord := w;
{$EndIf}
 End;

Function ConvULong(u: ULong): ULong;
Var
 u2: ULong;
 u2a: Array[1..4] of Byte absolute u2;
 p1: ^Byte;
 i: Byte;

 Begin
{$IfDef BigEndian}
 p1 := @u;
 For i := 1 to 4 do Begin u2a[5-i] := p1^; Inc(p1); End;
 ConvULong := u2;
{$Else}
 ConvULong := u;
{$EndIf}
 End;


Procedure DeCrypt(var Key: TRegInfo);
Type
 TBuf = Array[1..SizeOf(TRegInfo)] of Byte;

Var
 NewKey: TRegInfo;
 p1, p2: ^Byte;
 CCRC, DCRC: ULong;
 s1, s2: String;
 i: Byte;

 Begin
 p1 := @Key; p2 := @NewKey;
 s1[0] := #255; s2[0] := #255;
 For i := 1 to 255 do Begin s1[i] := #0; s2[i] := #0; End;
 NewKey.CryptCRC := Key.CryptCRC; NewKey.DeCryptCRC := Key.DeCryptCRC;
 {exclude CRCs}
 For i := 1 to SizeOf(TRegInfo)-8 do
  Begin
  p2^ := Byte(p1^ XOR (55+i));
  s1[i] := Char(p1^); s2[i] := Char(p2^);
{$IfDef FPC}
  Inc(ULong(p1)); Inc(ULong(p2));
{$Else}
  Inc(p1); Inc(p2);
{$EndIf}
  End;

 {Calculate CRCs}
 CCRC := CalcCRC(s1); DCRC := CalcCRC(s2);

 {porting stuff}
 NewKey.Addr.Zone := ConvWord(NewKey.Addr.Zone);
 NewKey.Addr.Net := ConvWord(NewKey.Addr.Net);
 NewKey.Addr.Node := ConvWord(NewKey.Addr.Node);
 NewKey.Addr.Point := ConvWord(NewKey.Addr.Point);
 NewKey.Serial := ConvULong(NewKey.Serial);
 NewKey.Copies := ConvULong(NewKey.Copies);
 NewKey.CryptCRC := ConvULong(NewKey.CryptCRC);
 NewKey.DeCryptCRC := ConvULong(NewKey.DeCryptCRC);

 {check Key}
 Key := NewKey;
 If (NewKey.Ver > Reg_MaxVersion) then Key := InvalidKey;
 If (NewKey.CryptCRC <> CCRC) then Key := InvalidKey;
 If (NewKey.DeCryptCRC <> DCRC) then Key := InvalidKey;
 End;

Procedure GetKey;
Var
  f: File of TRegInfo;
  s1, s2, s3: String;
  Dir: String;

  Begin
  FSplit(ParamStr(0), Dir, s1, s1);
  s2 := GetEnv('PT');
  FSplit(GetEnv('FIDOCONFIG'), s3, s1, s1);
{$IfDef UNIX}
  s1 := FSearch('protick.key', '.;'+Dir+';'+s2+';'+s3+';/etc/fido');
{$Else}
  s1 := FSearch('protick.key', '.;'+Dir+';'+s2+';'+s3+';c:\fido');
{$EndIf}
  If ((s1 = '') or (DOSError <> 0)) then RegInfo := EvalKey
  Else
    Begin
    Assign(f, s1);
    {$I-} ReSet(f); {$I+}
    If (IOResult <> 0) then RegInfo := EvalKey
    Else
      Begin
      {$I-} Read(f, RegInfo); {$I+}
      If (IOResult <> 0) then RegInfo := EvalKey Else DeCrypt(RegInfo);
      End;
    End;
  End;


Begin
GetKey;
end.
