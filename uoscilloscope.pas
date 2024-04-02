unit uOscilloscope;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  TAGraph, TASeries,DateUtils,Math;

type

  TPoint = record
    x,y:real;
  end;

  { TForm1 }
  TForm1 = class(TForm)
    btnInit: TButton;
    btnStart: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Chart1: TChart;
    cbUseLog: TCheckBox;
    cbStatic: TCheckBox;
    cbGenType: TComboBox;
    cbGenBehv: TComboBox;
    edIntBase: TEdit;
    edIntWidth: TEdit;
    edTimeScale: TEdit;
    edtFrequency: TEdit;
    edtAplitude: TEdit;
    edtShift: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Memo1: TMemo;
    oscSeries: TLineSeries;
    edDataLength: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Label1: TLabel;
    lbGenerators: TListBox;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure btnInitClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lbGeneratorsClick(Sender: TObject);
    procedure listGenerators;
    procedure Memo1Click(Sender: TObject);
  private

  public

  end;

  TTimer = class
    public
    lp:tdatetime;
    cp:tdatetime;
    dt:real;
    function getDeltaTime:real;
    procedure runTimer;
  end;

  TTmrRef = ^TTimer;
  TSeriesRef = ^TLineSeries;

  TGenerator = class
    public
      timerRef: TTmrRef;
      gType:integer;
      gBehv:integer;
      frequency,amplitude,phase,peakTime,mult:real;
      cArgVal,cFuncVal:real;
      function calcFunction(arg:real):real;
      procedure doTick;
      procedure SetTimer(tmr:TTmrRef);
      constructor Create;

  end;

  TOscilloscope = class
    private
      stop:boolean;
    public
      pause:boolean;
      timerRef: TTmrRef;
      generators:array of TGenerator;
      dataSet:array of TPoint;
      dataLen:integer;
      dataPos:integer;
      cArgVal:real;
      timeScale:real;
      outpSeries:TSeriesRef;
      procedure coreRun;
      procedure setTimer(tmr:TTmrRef);
      procedure setSeries(srs:TSeriesRef);
      procedure outputSeries;
      constructor Create(dl:integer;ts:real;tmr:TTmrRef;srs:TSeriesRef);
      property doStop: boolean read stop write stop;
      procedure addGenerator;
  end;




var
  Form1: TForm1;
  oscObj:TOscilloscope;
  mainTimer:TTimer;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.btnInitClick(Sender: TObject);
begin
  mainTimer:=TTimer.Create;
  FreeAndNil(oscObj);
  oscObj:=TOscilloscope.Create(
    strToInt(edDataLength.Text),
    strToFloat(edTimeScale.Text),
    @mainTimer,
    @oscSeries
  );
  btnStart.Enabled:=true;
  oscObj.coreRun;

end;

procedure TForm1.btnStartClick(Sender: TObject);
begin
  if oscObj.stop then
  begin
    oscObj.doStop:=false;
    oscObj.coreRun;
  end
  else
    oscObj.doStop:=true;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  oscObj.AddGenerator;
  oscObj.generators[high(oscObj.generators)].amplitude:=strtofloat(edtAplitude.Text);
  oscObj.generators[high(oscObj.generators)].frequency:=strtofloat(edtFrequency.Text);
  oscObj.generators[high(oscObj.generators)].phase:=strtofloat(edtShift.Text);
  oscObj.generators[high(oscObj.generators)].gType:=cbGenType.ItemIndex;
  oscObj.generators[high(oscObj.generators)].gBehv:=cbGenBehv.ItemIndex;
  listGenerators;
  lbGenerators.ItemIndex:=high(oscObj.generators);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  with oscObj do
  begin
    cArgVal:=0;
    dataLen:=strtoint(edDataLength.Text);
    dataPos:=0;
    timeScale:=strToFloat(edTimeScale.Text);
    SetLength(dataSet,dataLen);
    stop:=False;
    Form1.Memo1.Lines.Add('Oscilloscope reinit');
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if (lbGenerators.ItemIndex<>-1) then
  begin
  oscObj.generators[lbGenerators.ItemIndex].amplitude:=strtofloat(edtAplitude.Text);
  oscObj.generators[lbGenerators.ItemIndex].frequency:=strtofloat(edtFrequency.Text);
  oscObj.generators[lbGenerators.ItemIndex].phase:=strtofloat(edtShift.Text);
  oscObj.generators[lbGenerators.ItemIndex].gType:=cbGenType.ItemIndex;
  oscObj.generators[lbGenerators.ItemIndex].gBehv:=cbGenBehv.ItemIndex;
  listGenerators;
  end;

end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Chart1.LeftAxis.Range.UseMax:=True;
  Chart1.LeftAxis.Range.UseMin:=True;
  Chart1.LeftAxis.Range.Max:=StrToFloat(edIntBase.Text)+StrToFloat(edIntWidth.Text)/2;
  Chart1.LeftAxis.Range.Min:=StrToFloat(edIntBase.Text)-StrToFloat(edIntWidth.Text)/2;
  Chart1.Extent.UseYMin:=true;
  Chart1.Extent.UseYMax:=true;
  Chart1.Extent.YMin:=Chart1.LeftAxis.Range.Min;
  Chart1.Extent.YMax:=Chart1.LeftAxis.Range.Max;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Button4.Click;
end;

procedure TForm1.lbGeneratorsClick(Sender: TObject);
begin
  if (lbGenerators.ItemIndex<>-1) then
  begin
    cbGenType.ItemIndex:=oscObj.generators[lbGenerators.ItemIndex].gType;
    edtAplitude.Text:=floattostr(oscObj.generators[lbGenerators.ItemIndex].amplitude);
    edtFrequency.Text:=floattostr(oscObj.generators[lbGenerators.ItemIndex].frequency);
    edtShift.Text:=floattostr(oscObj.generators[lbGenerators.ItemIndex].phase);
    cbGenBehv.ItemIndex:=oscObj.generators[lbGenerators.ItemIndex].gBehv;
  end;
end;

procedure TForm1.listGenerators;
var i,ii:integer;
begin
  ii:=lbGenerators.ItemIndex;
  lbGenerators.Clear;
  if length(oscObj.generators)>0 then
  for i:=0 to high(oscObj.generators) do
  begin
    lbGenerators.AddItem(inttostr(i+1)+') '+cbGenType.Items[oscObj.generators[i].gType],nil);
  end;
  lbGenerators.ItemIndex:=ii;
end;

procedure TForm1.Memo1Click(Sender: TObject);
begin

end;

function TTimer.getDeltaTime:real;
var res:real;
begin
  lp:=cp;
  cp:=now;
  res:=MilliSecondsBetween(cp,lp)/1000;
  lp:=cp;
  result:=res;
end;

procedure TTimer.runTimer;
begin
  dt:=getDeltaTime;
end;

function TGenerator.calcFunction(arg:real):real;
begin
  //
  if (gType=0) then
  begin
    result:=amplitude*Sin(frequency*arg+phase);
  end;
end;

procedure TGenerator.doTick;
begin
  //
  cFuncVal:=calcFunction(cArgVal);
end;

procedure TGenerator.SetTimer(tmr:TTmrRef);
begin
  timerRef:=tmr;
end;


constructor TGenerator.Create;
begin
  gType:=0;
  amplitude:=10;
  frequency:=10;
  phase:=0;
end;

procedure TOscilloscope.SetTimer(tmr:TTmrRef);
begin
  timerRef:=tmr;
end;

procedure TOscilloscope.setSeries(srs:TSeriesRef);
begin
  outpSeries:=srs;
end;

procedure TOscilloscope.outputSeries;
var i:integer;
begin
  i:=High(dataSet);
  outpSeries^.AddXY(dataSet[i].x,dataSet[i].y);
  if outpSeries^.Count>dataLen then outpSeries^.Delete(0);
end;

procedure TOscilloscope.coreRun;
var i,l:integer;
  cVal:real;
  cPoint:TPoint;
begin
  if Form1.cbUseLog.Checked then
  Form1.Memo1.Lines.Add('Starting coreRun');

  while (true) do
  begin
    //get value from generators
    if (pause) then Continue;
    cVal:=0;
    l:=length(generators);

    cArgVal:=cArgVal+timerRef^.dt*timeScale;
    timerRef^.runTimer;
    if (l>0) then
    for i:=0 to l-1 do
    begin
      generators[i].cArgVal:=cArgVal;
      generators[i].doTick;
      if Form1.cbUseLog.Checked then
        Form1.Memo1.Lines.Add('Generator '+inttostr(i)+' tick');

      if generators[i].gBehv=0 then cVal:=cVal+generators[i].cFuncVal;
      if generators[i].gBehv=1 then cVal:=cVal*generators[i].cFuncVal;
      if generators[i].gBehv=2 then cVal:=cVal-generators[i].cFuncVal;
      if Form1.cbUseLog.Checked then
        Form1.Memo1.Lines.Add('Generator '+inttostr(i)+' calc');
    end;
    //record value to chart
    inc(dataPos);
    if (dataPos>=dataLen-1) then
    begin
      for i:=0 to dataLen-2 do dataSet[i]:=dataSet[i+1];
      dataPos:=dataLen-1;
    end;
    cPoint.x:=cArgVal;
    cPoint.y:=cVal;
    dataSet[dataPos]:=cPoint;

    //stop if static
    if (Form1.cbStatic.Checked) then
    if (dataPos=dataLen-1) then stop:=true;

    //redraw chart
    outputSeries;

    //log
    if Form1.cbUseLog.Checked then
    Form1.Memo1.Lines.Add(inttostr(dataPos)+') '+floatTostr(dataSet[dataPos].x)+';'+floatTostr(dataSet[dataPos].y));

    //NEEDED
    Application.ProcessMessages;

    if (doStop) then break;
  end;
end;



constructor TOscilloscope.Create(dl:integer;ts:real;tmr:TTmrRef;srs:TSeriesRef);
begin
  cArgVal:=0;
  dataLen:=dl;
  dataPos:=0;
  timeScale:=ts;
  setTimer(tmr);
  setSeries(srs);
  SetLength(dataSet,dataLen);
  stop:=False;
  Form1.Memo1.Lines.Add('Oscilloscope created');
end;

procedure TOscilloscope.addGenerator;
var n:integer;
begin
  pause:=true;
  setlength(generators,Length(generators)+1);
  n:=High(generators);
  generators[n]:=TGenerator.Create;
  pause:=false;
end;

end.

