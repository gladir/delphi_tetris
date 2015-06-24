{Author: Sylvain Maltais}
{Developer sous: Delphi 3}
{URL: http://www.gladir.com/CODER/DELPHI/tetris.htm}
Program TetrisConsole;
 
{$APPTYPE CONSOLE}
Uses Windows,SysUtils;
 
Const
 {Code de touche clavier renvoy‚e par ReadKey}
 kbNoKey=0;{Pas de touche}
 kbEsc=$011B;{Escape}
 kbUp=$4800;{Up}
 kbLeft=$0025;{FlŠche de gauche (Left)}
 kbKeypadLeft=$0064;{FlŠche de gauche (Left)}
 kbKeypad5NumLock=$0065;{5 du bloc num‚rique}
 kbKeypad5=$000C;{5 du bloc num‚rique}
 kbKeypadRight=$0066;{FlŠche de droite (Right)}
 kbRight=$0027;{FlŠche de droite (Right)}
 kbDn=$0028;{FlŠche du bas (Down)}
 kbKeypadDn=$0062;{FlŠche du bas (Down)}
 
 Black=0;
 
 
Type
 TetrisGame=Record
  Mode:(tmNone,tmStart,tmPlay,tmGameOver);
  Level:Byte;
  Score:LongInt;
  Bar,SLevel:Word;
  Tbl:Array[0..20,0..9]of Boolean; 
  Form,_Move,X,Y,Sleep:Byte;
  Touch,Ok:Boolean;
  SleepDelay:Byte;
  FBar:Word;
  UpDate:Boolean;
 End;
 
Function  TetrisInit(Var Q:TetrisGame):Boolean;Forward;
Procedure TetrisStart(Var Q:TetrisGame);Forward;
Procedure TetrisRefresh(Var Q:TetrisGame);Forward;
Function  TetrisPlay(Var Q:TetrisGame):Word;Forward;
 
Const
 HomeX=15;
 HomeY=2;
 CurrX1:Byte=0;
 CurrY1:Byte=0;
 CurrX2:Byte=79;
 CurrY2:Byte=24;
 
Procedure GotoXY(X,Y:Byte);
Var
 _Pos:TCoord;
Begin
 _Pos.X:=X;
 _Pos.Y:=Y;
 SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE),_Pos);
End;
 
Procedure TextAttr(Attr:Byte);Begin
 SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE),Attr);
End;
 
Procedure TextBackground(Color:Byte);
Var
 Info:TConsoleScreenBufferInfo;
Begin
 GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE),Info);
 TextAttr((Color shl 4)+(Info.wAttributes and $F));
End;
 
Procedure TextForeground(Color:Byte);
Var
 Info:TConsoleScreenBufferInfo;
Begin
 GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE),Info);
 TextAttr((Info.wAttributes shl 4)+(Color and $F));
End;
 
Procedure Window(X1,Y1,X2,Y2:Byte);Begin
 CurrX1:=X1;
 CurrY1:=Y1;
 CurrX2:=X2;
 CurrY2:=Y2;
End;
 
Procedure ClrScr;
Var
 _Pos:TCoord;
 Console:THandle;
 Info:TConsoleScreenBufferInfo;
 Output:DWORD;
 J:Word;
Begin
 Console:=GetStdHandle(STD_OUTPUT_HANDLE);
 GetConsoleScreenBufferInfo(Console,Info);
 FillChar(_Pos,SizeOf(_Pos),0);
 GotoXY(0,0);
 For J:=CurrY1 to CurrY2 do Begin
  _Pos.X:=CurrX1;
  _Pos.Y:=J;
  FillConsoleOutputCharacter(Console,#32 ,CurrX2-CurrX1+1,_Pos,Output);
  FillConsoleOutputAttribute(Console,Info.wAttributes,CurrX2-CurrX1+1,_Pos,Output);
 End;
 GotoXY(0,0);
End;
 
Function KeyPressed:Boolean;
Var
 Nbr:DWORD;
 Q:TInputRecord;
Begin
 Nbr:=0;
 PeekConsoleInput(GetStdHandle(STD_INPUT_HANDLE),Q,1,Nbr);
 KeyPressed:=Nbr>0;
End;
 
Function ReadKey:Char;
Var
 Console:THandle;
 K:DWORD;
 Q:TInputRecord;
Begin
 ReadKey:=#0 ;
 K:=0;
 Console:=GetStdHandle(STD_INPUT_HANDLE);
 PeekConsoleInput(Console,Q,1,K);
 If K>0Then Begin
  ReadConsoleInput(Console,Q,1,K);
  If((Q.EventType=1)and(Q.KeyEvent.bKeyDown))Then Begin
   ReadKey:=Char(Q.KeyEvent.wVirtualKeyCode);
  End;
 End;
End;
 
Procedure WaitRetrace;Begin
 Sleep(1000 div 60);
End;
 
Procedure MoveRight(Const Source;Var Dest;_Length:LongInt);Begin
 Move(Source,Dest,_Length);
End;
 
Procedure MoveText(X1,Y1,X2,Y2,X3,Y3:Byte);
Var
 Console:THandle;
 Info:TConsoleScreenBufferInfo;
 lpScrollRectangle,lpClipRectangle:TSmallRect;
 dwDestinationOrigin:TCoord;
 lpFill:TCharInfo;
Begin
 Console:=GetStdHandle(STD_OUTPUT_HANDLE);
 GetConsoleScreenBufferInfo(Console,Info);
 lpScrollRectangle.Left:=X1;
 lpScrollRectangle.Top:=Y1;
 lpScrollRectangle.Right:=X2;
 lpScrollRectangle.Bottom:=Y2+(Y3-Y1);
 lpClipRectangle:=lpScrollRectangle;
 Dec(lpScrollRectangle.Bottom);
 dwDestinationOrigin.X:=lpScrollRectangle.Left;
 dwDestinationOrigin.Y:=lpScrollRectangle.Top + (Y3-Y1);
 lpFill.UnicodeChar:=' ';
 lpFill.Attributes:=Info.wAttributes;
 ScrollConsoleScreenBuffer(Console,lpScrollRectangle,@lpClipRectangle,dwDestinationOrigin,lpFill);
End;
 
Procedure BarSpcHor(X1,Y,X2:Byte);Begin
 Window(X1,Y,X2,Y);
 ClrScr;
 Window(1,1,40,25);
End;
 
Function TetrisInit(Var Q:TetrisGame):Boolean;Begin
 FillChar(Q,SizeOf(Q),0);
 Q.Level:=1;
 Q.Mode:=tmStart;
End;
 
Procedure TetrisStart(Var Q:TetrisGame); 
Var 
 I:Byte;
Begin 
 FillChar(Q.Tbl,SizeOf(Q.Tbl),0); 
 FillChar(Q.Tbl[20],SizeOf(Q.Tbl[20]),Byte(True)); 
 Q.Score:=0;Q.Bar:=0;Q.SleepDelay:=25;Q.Level:=Q.SLevel;
 For I:=0to(Q.SLevel)do If Q.SleepDelay>6Then Dec(Q.SleepDelay,2); 
 Q.FBar:=Q.Level shl 4; 
 Q.Mode:=tmStart; 
End;
 
Procedure TetrisRefresh(Var Q:TetrisGame);
Var
 I,J:Byte;
Begin
 TextBackground(1+Q.Level);
 ClrScr;
 GotoXY(3,2);Write('Niveau:');
 GotoXY(4,3);Write(Q.Level);
 GotoXY(3,5);Write('Pointage:');
 GotoXY(4,6);Write('0');
 GotoXY(3,8);Write('Ligne:');
 GotoXY(4,9);Write(Q.Bar);
 Window(HomeX,HomeY,HomeX+9,HomeY+19);
 TextBackground(Black);
 ClrScr;
 Window(1,1,40,25);
 If(Q.Mode)in[tmPlay,tmGameOver]Then Begin
  For J:=0to 19do For I:=0to 9do If Q.Tbl[J,I]Then Begin
   GotoXY(HomeX+I,HomeY+J);Write('þ');
  End;
 End;
End;
 
Function TetrisPlay(Var Q:TetrisGame):Word;Label _Exit;Const
      BlkHeight:Array[0..6,0..3]of Byte=( 
       (4,1,4,1), { Barre } 
       (2,2,2,2), { BoŒte } 
       (3,2,3,2), { V } 
       (3,2,3,2), { L gauche }
       (3,2,3,2), { L droite } 
       (3,2,3,2), { Serpent romain } 
       (3,2,3,2));{ Serpent arabe } 
      BlkLength:Array[0..6,0..3]of Byte=( {Largeur des objets:} 
       (1,4,1,4), { Barre } 
       (2,2,2,2), { BoŒte } 
       (2,3,2,3), { V } 
       (2,3,2,3), { L gauche } 
       (2,3,2,3), { L droite } 
       (2,3,2,3), { Serpent romain }
       (2,3,2,3));{ Serpent arabe } 
      BlkFormat:Array[0..6,0..3,0..3]of Record X,Y:Byte;End=( 
       (((X:0;Y:0),(X:0;Y:1),(X:0;Y:2),(X:0;Y:3)),   { þþþþ } 
        ((X:0;Y:0),(X:1;Y:0),(X:2;Y:0),(X:3;Y:0)),
        ((X:0;Y:0),(X:0;Y:1),(X:0;Y:2),(X:0;Y:3)), 
        ((X:0;Y:0),(X:1;Y:0),(X:2;Y:0),(X:3;Y:0))), 
       (((X:0;Y:0),(X:1;Y:0),(X:0;Y:1),(X:1;Y:1)),   { þþ } 
        ((X:0;Y:0),(X:1;Y:0),(X:0;Y:1),(X:1;Y:1)),   { þþ } 
        ((X:0;Y:0),(X:1;Y:0),(X:0;Y:1),(X:1;Y:1)),
        ((X:0;Y:0),(X:1;Y:0),(X:0;Y:1),(X:1;Y:1))), 
       (((X:1;Y:0),(X:0;Y:1),(X:1;Y:1),(X:1;Y:2)),   { þþþ } 
        ((X:1;Y:0),(X:0;Y:1),(X:1;Y:1),(X:2;Y:1)),   { þ } 
        ((X:0;Y:0),(X:0;Y:1),(X:1;Y:1),(X:0;Y:2)), 
        ((X:0;Y:0),(X:1;Y:0),(X:2;Y:0),(X:1;Y:1))),
       (((X:0;Y:0),(X:0;Y:1),(X:0;Y:2),(X:1;Y:2)), 
        ((X:0;Y:1),(X:1;Y:1),(X:2;Y:1),(X:2;Y:0)),   { þ } 
        ((X:0;Y:0),(X:1;Y:0),(X:1;Y:1),(X:1;Y:2)),   { þ } 
        ((X:0;Y:0),(X:1;Y:0),(X:2;Y:0),(X:0;Y:1))),  { þþ } 
       (((X:1;Y:0),(X:1;Y:1),(X:1;Y:2),(X:0;Y:2)), 
        ((X:0;Y:1),(X:1;Y:1),(X:2;Y:1),(X:0;Y:0)),   { þ } 
        ((X:1;Y:0),(X:0;Y:0),(X:0;Y:1),(X:0;Y:2)),   { þ } 
        ((X:0;Y:0),(X:1;Y:0),(X:2;Y:0),(X:2;Y:1))),  { þþ } 
       (((X:0;Y:0),(X:0;Y:1),(X:1;Y:1),(X:1;Y:2)), 
        ((X:1;Y:0),(X:2;Y:0),(X:0;Y:1),(X:1;Y:1)), 
        ((X:0;Y:0),(X:0;Y:1),(X:1;Y:1),(X:1;Y:2)), 
        ((X:1;Y:0),(X:2;Y:0),(X:0;Y:1),(X:1;Y:1))), 
       (((X:1;Y:0),(X:0;Y:1),(X:1;Y:1),(X:0;Y:2)), 
        ((X:0;Y:0),(X:1;Y:0),(X:1;Y:1),(X:2;Y:1)),
        ((X:1;Y:0),(X:0;Y:1),(X:1;Y:1),(X:0;Y:2)),   {þþ } 
        ((X:0;Y:0),(X:1;Y:0),(X:1;Y:1),(X:2;Y:1)))); { þþ }
Var 
 I,J,H,XT:Byte; 
 XJ,YJ,K:Word;
 Touch,Ok,NoAction:Boolean; 
 
 Procedure PutForm(Clr:Boolean); 
 Var 
  Chr:Char;
  I,Attr,X,Y:Byte; 
 Begin 
  X:=HomeX+Q.X;
  Y:=HomeY+Q.Y;
  If(Clr)Then Begin 
   Chr:=' ';Attr:=7; 
  End 
   Else 
  Begin 
   Chr:='þ';Attr:=$71+Q.Form; 
  End; 
  For I:=0to 3do Begin 
   GotoXY(HomeX+Q.X+BlkFormat[Q.Form,Q._Move,I].X,
                            HomeY+Q.Y+BlkFormat[Q.Form,Q._Move,I].Y);
   TextAttr(Attr); 
   Write(Chr); 
   TextAttr(7); 
  End; 
 End;
 
 Procedure Init;Begin 
  Q.Form:=Random(6);
  If Q.Form=5Then Inc(Q.Form,Random(2)); 
  Q.X:=5;Q.Y:=0;
  Q._Move:=0;Q.Sleep:=0;
  PutForm(False); 
 End; 
 
 Function UpDateData:Boolean; 
 Var 
  H,I,J,JK:Byte;
  Bonus:Byte; 
  LnChk:Boolean; 
 Begin 
  UpDateData:=True;Q.Sleep:=0; 
  PutForm(False); 
  Touch:=False;Ok:=False; 
  PutForm(True);
  Inc(Q.Y); 
  For I:=0to 3do Begin 
   Touch:=Touch or Q.Tbl[Q.Y+BlkFormat[Q.Form,Q._Move,I].Y,Q.X+BlkFormat[Q.Form,Q._Move,I].X];
  End; 
  If(Touch)Then Dec(Q.Y);
  PutForm(False); 
  If(Touch)Then Begin 
   While(Q.Sleep>Q.SleepDelay)do Dec(Q.Sleep); 
   Q.Sleep:=0;Ok:=True; 
   For I:=0to 3do Q.Tbl[Q.Y+BlkFormat[Q.Form,Q._Move,I].Y,Q.X+BlkFormat[Q.Form,Q._Move,I].X]:=True;
   If Q.Level>7Then Begin 
    Inc(Q.Score,LongInt(5)*Q.Level);
    GotoXY(4,6);Write(Q.Score); 
   End;
   Bonus:=0; 
   For J:=0to 19do Begin 
    Touch:=True; 
    For I:=0to 9do Touch:=Touch and Q.Tbl[J,I]; 
    If(Touch)Then Inc(Bonus); 
   End; 
   If Bonus>0Then Dec(Bonus); 
   Touch:=False; 
   For JK:=0to 7do Begin 
    For J:=0to 19do Begin
     LnChk:=True; 
     For I:=0to 9do LnChk:=LnChk and Q.Tbl[J,I]; 
     If(LnChk)Then Begin 
      If Not(Touch)Then Begin 
       Touch:=True;
      End; 
      If JK and 1=0Then TextAttr($FF)
                   Else TextAttr(7); 
      BarSpcHor(HomeX,HomeY+J,HomeX+9); 
     End;
    End; 
    WaitRetrace;WaitRetrace;WaitRetrace; 
   End; 
   For J:=0to 19do Begin 
    Touch:=True; 
    For I:=0to 9do Touch:=Touch and Q.Tbl[J,I]; 
    If(Touch)Then Begin 
     MoveRight(Q.Tbl[0,0],Q.Tbl[1,0],10*J); 
     FillChar(Q.Tbl[0,0],10,0); 
     MoveText(HomeX,HomeY,HomeX+9,HomeY+J-1,HomeX,HomeY+1);
     Inc(Q.Score,LongInt(5)+(Bonus*4)*(Q.Level+1)+10*Q.Level); Inc(Q.Bar); 
     GotoXY(4,6);Write(Q.Score); 
     GotoXY(4,9);Write(Q.Bar); 
     I:=(Q.Bar+Q.FBar)shr 4;
     If(Q.Level<>I)Then Begin 
      Q.Level:=I;
      GotoXY(4,3);Write(Q.Level+1); 
      If Q.SleepDelay>6Then Dec(Q.SleepDelay,2); 
     End;
    End; 
   End; 
   If Q.Y<=1Then Begin 
    UpDateData:=False; 
    Exit;
   End; 
   Init; 
  End; 
 End; 
 
 Function GameOver:Word;Begin 
  GotoXY(10,7);Write('Partie Terminer'); 
  If(Q.UpDate)Then Begin 
   Q.UpDate:=False; 
  End;
  GameOver:=kbEsc;
 End; 
 
Begin
 TetrisRefresh(Q);
 K:=0; 
 Repeat 
  Case(Q.Mode)of 
   tmStart:Begin
    TetrisStart(Q); 
    TetrisRefresh(Q); 
    Init;
    Q.Mode:=tmPlay;Q.UpDate:=True; 
   End;
   tmPlay:Repeat 
    Begin
     Repeat
      If(Q.Sleep>Q.SleepDelay)Then If Not(UpDateData)Then Begin
       Q.Mode:=tmGameOver;
       Goto _Exit;
      End;
      WaitRetrace;
      Inc(Q.Sleep);
     Until KeyPressed;
     K:=Byte(ReadKey);
    End;
    If Chr(K)='2'Then K:=kbDn;
    If Chr(K)='4'Then K:=kbLeft;
    If Chr(K)='6'Then K:=kbRight;
    NoAction:=False;
    Case(K)of
     kbLeft,kbKeypadLeft:If Q.X>0Then Begin
      Touch:=False;
      For I:=0to 3do Touch:=Touch or Q.Tbl[Q.Y+BlkFormat[Q.Form,Q._Move,I].Y,Q.X+BlkFormat[Q.Form,Q._Move,I].X-1];
      If Not(Touch)Then Begin
       PutForm(True);
       Dec(Q.X);
       PutForm(False);
      End;
     End;
     kbRight,kbKeypadRight:If Q.X+BlkLength[Q.Form,Q._Move]-1<9Then Begin
      Touch:=False;
      For I:=0to 3do Touch:=Touch or Q.Tbl[Q.Y+BlkFormat[Q.Form,Q._Move,I].Y,Q.X+BlkFormat[Q.Form,Q._Move,I].X+1];
      If Not(Touch)Then Begin
       PutForm(True);
       Inc(Q.X);
       PutForm(False);
      End;
     End;
     kbDn,kbKeypadDn:While(True)do Begin
      If Not(UpDateData)Then Begin
       Q.Mode:=tmGameOver;
       Goto _Exit;
      End;
      If(Ok)Then Break;
     End;
     Else NoAction:=True;
    End;
    If(NoAction)Then Begin
     If(K in[kbKeyPad5,kbKeypad5NumLock])or(Char(K)in[' ','5'])Then Begin
      Touch:=False;
      For I:=0to 3do Begin
       XT:=Q.X+BlkFormat[Q.Form,(Q._Move+1)and 3,I].X; Touch:=Touch or(XT>9);
       Touch:=Touch or Q.Tbl[Q.Y+BlkFormat[Q.Form,(Q._Move+1)and 3,I].Y,XT];
      End; 
      If Not(Touch)Then Begin 
       PutForm(True);
       Q._Move:=(Q._Move+1)and 3;
       PutForm(False) 
      End 
       Else
      Begin 
       Touch:=False; 
       For I:=0to 3do Begin 
        XT:=Q.X;
        If XT>0Then Dec(XT);
        Inc(XT,BlkFormat[Q.Form,(Q._Move+1)and 3,I].X); Touch:=Touch or(XT>9);
        Touch:=Touch or Q.Tbl[Q.Y+BlkFormat[Q.Form,(Q._Move+1)and 3,I].Y,XT];
       End;
       If Not(Touch)Then Begin
        PutForm(True);
        Dec(Q.X); Q._Move:=(Q._Move+1)and 3;
        PutForm(False);
       End;
      End;
     End
      Else
     Break;
    End;
   Until(K=kbEsc)or(Chr(K)='Q');
   tmGameOver:K:=GameOver;
  End;
_Exit: 
  If K<>0Then Break; 
 Until False; 
 TetrisPlay:=K; 
End; 
 
Var 
 Game:TetrisGame;
 
BEGIN 
 TetrisInit(Game); 
 TetrisPlay(Game); 
END.