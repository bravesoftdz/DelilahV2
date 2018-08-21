unit delilah.order.gdax;

{$mode delphi}

interface

uses
  Classes, SysUtils, delilah.types, delilah.order, gdax.api.types,
  gdax.api.consts, ledger;

type

  { IGDAXOrderDetails }

  IGDAXOrderDetails = interface(IOrderDetails)
    ['{91294778-1291-44C4-87B4-A25779C3CF19}']
    //property methods
    function GetOrder: IGDAXOrder;
    procedure SetOrder(Const AValue: IGDAXOrder);
    //properties
    property Order : IGDAXOrder read GetOrder write SetOrder;
  end;

  { TGDAXOrderDetailsImpl }
  (*
    order details adapter for a gdax order
  *)
  TGDAXOrderDetailsImpl = class(TOrderDetailsImpl,IGDAXOrderDetails)
  strict private
    FOrder: IGDAXOrder;
    function GetOrder: IGDAXOrder;
    procedure SetOrder(Const AValue: IGDAXOrder);
  strict protected
    function DoGetPrice: Extended; override;
    function DoGetSize: Extended; override;
    function DoGetType: TOrderDetailsType; override;
    procedure DoSetPrice(const AValue: Extended); override;
    procedure DoSetSize(const AValue: Extended); override;
    procedure DoSetType(const AValue: TOrderDetailsType); override;
  public
    property Order : IGDAXOrder read GetOrder write SetOrder;
    constructor Create(Const AOrder:IGDAXOrder); overload;
    destructor Destroy; override;
  end;

implementation

{ TGDAXOrderDetailsImpl }

function TGDAXOrderDetailsImpl.GetOrder: IGDAXOrder;
begin
  Result:=FOrder;
end;

procedure TGDAXOrderDetailsImpl.SetOrder(const AValue: IGDAXOrder);
begin
  FOrder:=nil;
  FOrder:=AValue;
end;

function TGDAXOrderDetailsImpl.DoGetPrice: Extended;
begin
  if not Assigned(FOrder) then
    Exit(0);
  (*
    below we are using the ExecutedValue which is only present on orders
    after 2016, but is the cumulative (size * price), so we don't have to make
    a second call to the fills endpoint. only market orders will have fill fees
    as of writing this, but this accounts if coinbase decides to charge for
    limit orders as well
  *)

  //for buy orders we need to add the fees to price to show higher cost
  if FOrder.Side=osBuy then
    Result:=((FOrder.ExecutedValue + Abs(FOrder.FillFees)) / FOrder.FilledSized)
  //but for sell orders we need to subtract any fees to show reduction in profit
  else
    Result:=((FOrder.ExecutedValue - Abs(FOrder.FillFees)) / FOrder.FilledSized)
end;

function TGDAXOrderDetailsImpl.DoGetSize: Extended;
begin
  if not Assigned(FOrder) then
    Exit(0);
  //when an order is completed we have to differentiate between
  //requested size, and what was actually filled. here we choose
  //to report the filled size in this manner, but may change pending use
  if FOrder.OrderStatus in [stSettled,stDone] then
    Result:=FOrder.FilledSized
  else
    Result:=FOrder.Size;
end;

function TGDAXOrderDetailsImpl.DoGetType: TOrderDetailsType;
begin
  if not Assigned(FOrder) then
    raise Exception.Create('GDAX order not assigned in ' + Self.Classname);
  if FOrder.Side=osBuy then
    Result:=odBuy
  else
    Result:=odSell;
end;

procedure TGDAXOrderDetailsImpl.DoSetPrice(const AValue: Extended);
begin
  if not Assigned(FOrder) then
    raise Exception.Create('GDAX order not assigned in ' + Self.Classname);
  FOrder.Price:=AValue;
end;

procedure TGDAXOrderDetailsImpl.DoSetSize(const AValue: Extended);
begin
  if not Assigned(FOrder) then
    raise Exception.Create('GDAX order not assigned in ' + Self.Classname);
  FOrder.Size:=AValue;
end;

procedure TGDAXOrderDetailsImpl.DoSetType(const AValue: TOrderDetailsType);
begin
  if not Assigned(FOrder) then
    raise Exception.Create('GDAX order not assigned in ' + Self.Classname);
  if AValue=odBuy then
    FOrder.Side:=osBuy
  else
    FOrder.Side:=osSell;
end;


constructor TGDAXOrderDetailsImpl.Create(const AOrder: IGDAXOrder);
begin
  inherited Create;
  FOrder:=AOrder;
end;

destructor TGDAXOrderDetailsImpl.Destroy;
begin
  FOrder:=nil;
  inherited Destroy;
end;

end.

