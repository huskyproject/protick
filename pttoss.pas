Program PTToss;
{
- ScanForTICs
- read TIC (using unit TIC)
- CheckTIC
  - CheckSize
- AutoCreate
  - areaname masks like "BBS-*" for all BBSNet-Areas
    (<one AKA, multiple groups>-problem)
- ProcessTIC
- ForwardTIC
  - AddToArcList
    - using Address+Pointer-B-Tree
- Extract and use FILE_ID.DIZ / LSM, order configurable
- write magics from TIC to a configurable file (add/replace appropriate line)
- execute script after single files / each file
}

Uses
 Log;


Begin
End.

