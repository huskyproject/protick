Unit PTVar;

InterFace
{$IfDef FPC}
 {$PackRecords 1}
{$EndIf}

Uses
  Types, TickType, IniFile, MKMsgAbs, PTOut;

Const
{$IfDef OS2}
 _Version = '/2 '
{$Else}
 {$IfDef UNIX}
 _Version = '/Lx '
 {$Else}
  {$IfDef DPMI}
  _Version = '/16 '
  {$Else}
  _Version = '/8 '
  {$EndIf}
 {$EndIf}
{$EndIf}

  + '0.9beta4';

Var
  Version: String;
  LogHandle: Byte;
  Debug: Boolean;
  Cfg: PTickCfg;
  Ini: IniObj;
  NM: AbsMsgPtr;
  NM2: AbsMsgPtr;
  CfgName: String;
  DupeCheck: Boolean;
  Command: String;
  CurUser: PUser;
  CurUpLink: PUpLink;
  CurConnUser: PConnectedUser;
  CurArea: PArea;
  CurAnnGroup: PAnnGroup;
  CurAnnArea: PAnnAreaEntry;
  CurAnnFile: PAnnFileEntry;
  AnnMsg: AbsMsgPtr;
  AnnAreas: PAnnAreaEntry;
  AnnFiles: PAnnFileEntry;
  HArea: String;
  HFrom, HTo, HOrigin: TNetAddr;
  HFile: String;
  HMove: Boolean;
  HReplace: String;
  HDesc: PChar2;
  HPW: String;
  MainDone: Procedure;
  ArcList: File of TArcListEntry;
  ALE: TArcListEntry;
  PTList: File of TPTListEntry;
  PTLE: TPTListEntry;
  AutoAddList, TossList: PAreaList;
  CurAutoAddList, CurTossList: PAreaList;
  DFUE_Handle: Word;
  CreatedBsy: Boolean;
  Outbound: pOutbound;


Implementation
End.
