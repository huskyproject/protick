Unit Misc;

Interface
{
- check busy file
- MsgID
- append error message to TIC
  - AppendErrorStrTIC(ErrNum: Byte)
- create newareas.pt, areas.log
  - AddAutoCreatedArea(name: string)
  - AddProcessedArea(name: string)
  - WriteAutoCreatedAreas
  - WriteProcessedAreas
  - using PChar-B-Tree
- Addr2Str
- Str2Addr
- CompAddr
- CopyAddr
- write netmail on errors
- some global types
}

Implementation

Begin
End.

