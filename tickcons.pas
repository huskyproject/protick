Unit TickCons;
Interface

Uses
  TickType;

Const
  {Errors}
  Err_NoParams      = 1;
  Err_UnKnownCommand = 2;
  Err_Ini           = 3;
  Err_NoCfg         = 4;
  Err_NoLog         = 5;
  Err_ArcList       = 6;
  Err_Bsy           = 7;
  Err_PTList        = 8;

  Err_Internal      = 250;

  {Cfg.OBType}
  OB_BT             = 1;
  OB_FD             = 2;
  OB_TMail          = 3;

  {FileArea.Flags}
  fa_PT             = 1;
  fa_Dupe           = 2;
  fa_CRC            = 4;
  fa_Touch          = 8;
  fa_Mandatory      = 32;
  fa_NoPause        = 64;
  fa_NewFilesHatch  = 128;
  fa_CS             = 256;
  fa_Hidden         = 512;
  fa_RemoteChange   = 1024;

  {User.MailFlags}
  ml_Normal         = 1;
  ml_Direct         = 2;
  ml_Hold           = 3;
  ml_Crash          = 4;
  ml_Imm            = 5;

  {User.Flags}
  uf_SendTIC        = 1;
  uf_Notify         = 2;
  uf_AutoCreate     = 4;
  uf_Admin          = 8;
  uf_NMAnn          = 16;

  {User.May}
  um_Connect        = 1;
  um_DisConnect     = 2;
  um_Pause          = 4;
  um_Pwd            = 8;
  um_Compression    = 16;
  um_TIC            = 32;
  um_Notify         = 64;
  um_Rescan         = 128;

  {BadTIC}
  bt_NoFile         = 1;
  bt_CRC            = 2;
  bt_UnknownArea    = 3;
  bt_NotConnected   = 4;
  bt_NoSend         = 5;
  bt_WrongPwd       = 6;
  bt_CouldntMove    = 7;
  bt_Dupe           = 8;
  bt_NotForUs       = 9;
  bt_UnListed       = 10;

  {Action for OutBound}
  ac_Nothing        = 0;
  ac_Del            = 1;
  ac_Trunc          = 2;

  {Responses}
  rs_Unlisted       = 1;
  rs_WrongPwd       = 2;
  rs_UnKnownCmd     = 3;
  rs_NoDisConnect   = 4;
  rs_NoConnect      = 5;
  rs_NoReScan       = 6;
  rs_UnKnownArea    = 7;
  rs_AlreadyConn    = 8;
  rs_NotConn        = 9;
  rs_NoPause        = 10;
  rs_NoComp         = 11;
  rs_UnKnownPacker  = 12;
  rs_List           = 13;
  rs_NotImplemented = 14;
  rs_Help           = 15;
  rs_ParamNeeded    = 16;
  rs_Connect        = 17;
  rs_DisConnect     = 18;
  rs_Pause          = 19;
  rs_Resume         = 20;
  rs_PackFiles      = 21;
  rs_PackTICs       = 22;
  rs_Packer         = 23;
  rs_NoRemote       = 24;
  rs_Mandatory      = 25;
  rs_Query          = 26;
  rs_Unlinked       = 27;

  {Announcegroup.Type}
  at_Echomail       = 0;
  at_Netmail        = 1;

  EmptyAddr         : TNetAddr = (Zone:0; Net:0; Node:0; Point:0; Domain:'');

Implementation

End.
