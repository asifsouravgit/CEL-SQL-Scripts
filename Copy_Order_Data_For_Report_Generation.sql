CREATE PROCEDURE [dbo].[CopyOrderDataForReportGeneration]
@SystemID INT=NULL, @StartDate DATETIME=NULL, @EndDate DATETIME=NULL
AS
SET NOCOUNT ON;

DECLARE @OrderIDs TABLE (OrderID INT NULL);

BEGIN TRANSACTION;
BEGIN TRY

INSERT INTO @OrderIDs
SELECT DISTINCT OrderID FROM SalesOrders WHERE SystemID = @SystemID
AND CAST(OrderDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE);

DELETE FROM SalesOrderPromotionRpt WHERE SalesOrderID IN (SELECT DISTINCT OrderID FROM @OrderIDs);
DELETE FROM SalesOrderItemRpt WHERE OrderID IN (SELECT DISTINCT OrderID FROM @OrderIDs);
DELETE FROM SalesOrdersRpt WHERE OrderID IN (SELECT DISTINCT OrderID FROM @OrderIDs);

INSERT INTO SalesOrdersRpt(OrderID, OrderNo, OrderDate, SystemID, SalesPointID, SystemType, SalesType, RefNo, 
ChallanID, CustomerID, RouteID, SectionID, SRID, MHNodeID, OrderStatus, OrderSource, GrossValue, 
FreeValue, PromoDiscValue, OtherDiscValue, VATValue, NetValue, CheckInTime, CheckOutTime, 
OrderLatitude, OrderLongitude, NoOrderReasonID, ExpectedDeliveryDate, CreatedBy, CreatedDate,
ModifiedBy, ModifiedDate, DeliveryLocation, ModeOfOrder, SpecialDiscValue, ReceivedAmount,
LocDifference, IsAccuratelocation, RouteCompliance, CASHPAID)
SELECT OrderID, OrderNo, OrderDate, SystemID, SalesPointID, SystemType, SalesType, RefNo, 
ChallanID, CustomerID, RouteID, SectionID, SRID, MHNodeID, OrderStatus, OrderSource, GrossValue, 
FreeValue, PromoDiscValue, OtherDiscValue, VATValue, NetValue, CheckInTime, CheckOutTime, 
OrderLatitude, OrderLongitude, NoOrderReasonID, ExpectedDeliveryDate, CreatedBy, CreatedDate,
ModifiedBy, ModifiedDate, DeliveryLocation, ModeOfOrder, SpecialDiscValue, ReceivedAmount,
LocDifference, IsAccuratelocation, RouteCompliance, CASHPAID
FROM SalesOrders WHERE OrderID IN (SELECT DISTINCT OrderID FROM @OrderIDs);

INSERT INTO SalesOrderItemRpt(ItemID, OrderID, SKUID, Quantity, OriginalQuantity, FreeQty, 
SoldQuantity, FreeQtySold, CostPrice, TradePrice, InvoicePrice, MRPrice, VATRate, 
DiscountRate, BatchNo, BatchMfgDate, BatchExpDate, SpecialDiscount, CPQuantity)
SELECT ItemID, OrderID, SKUID, Quantity, OriginalQuantity, FreeQty, 
SoldQuantity, FreeQtySold, CostPrice, TradePrice, InvoicePrice, MRPrice, VATRate, 
DiscountRate, BatchNo, BatchMfgDate, BatchExpDate, SpecialDiscount, CPQuantity
FROM SalesOrderItem WHERE OrderID IN (SELECT DISTINCT OrderID FROM @OrderIDs);

INSERT INTO SalesOrderPromotionRpt(OrderPromoID, SalesOrderID, SalesPromotionID, SlabID, 
BonusType, FreeSKUID, GiftItemID, BonusValue, OfferedQty, Threshold)
SELECT OrderPromoID, SalesOrderID, SalesPromotionID, SlabID, 
BonusType, FreeSKUID, GiftItemID, BonusValue, OfferedQty, Threshold
FROM SalesOrderPromotion WHERE SalesOrderID IN (SELECT DISTINCT OrderID FROM @OrderIDs);

COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK;
END CATCH

SET NOCOUNT OFF;
RETURN;