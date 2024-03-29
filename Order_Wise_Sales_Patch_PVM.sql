ALTER PROCEDURE [dbo].[OrderWiseSalesPatch]
@StartDate DATETIME, @EndDate DATETIME
AS
SET NOCOUNT ON;

DECLARE TmpOrdInvoices CURSOR FOR
SELECT SI.OrderID, COUNT(*) InvoiceCount FROM SalesInvoices SI 
WHERE SI.OrderID IS NOT NULL AND 
SI.InvoiceDate BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)
GROUP BY SI.OrderID HAVING COUNT(*) > 1;

DECLARE @OrderID INT, @InvoiceCount INT, @OuterLoop INT, @InnerLoop INT, @OrderIDInsCount INT,
@InvoiceID INT, @InvoiceDate DATETIME, @InvoiceCustomerID INT, @InvoiceSRID INT,
@InvoiceSectionID INT, @InvoiceGrossValue MONEY, @InvOrderIDWithGrossMatch INT, @InvOrderID INT;
DECLARE @OrderIDCheck TABLE (OrderID INT NULL);

BEGIN TRANSACTION;
BEGIN TRY

OPEN TmpOrdInvoices
FETCH NEXT FROM TmpOrdInvoices INTO @OrderID, @InvoiceCount
SET @OuterLoop = @@FETCH_STATUS
WHILE @OuterLoop = 0
BEGIN

IF(ISNULL(@OrderID, 0) > 0 AND ISNULL(@InvoiceCount, 0) > 1)
BEGIN
	DECLARE TmpInvoices CURSOR FOR
	SELECT SI.InvoiceID, SI.InvoiceDate, SI.CustomerID, SI.SRID, SI.SectionID, SI.GrossValue
	FROM SalesInvoices SI WHERE SI.OrderID = @OrderID;
	
	UPDATE SalesInvoices SET OrderID = NULL WHERE OrderID = @OrderID;
	
	OPEN TmpInvoices
	FETCH NEXT FROM TmpInvoices INTO @InvoiceID, @InvoiceDate, @InvoiceCustomerID, @InvoiceSRID, @InvoiceSectionID, @InvoiceGrossValue
	SET @InnerLoop = @@FETCH_STATUS
	WHILE @InnerLoop = 0
	BEGIN
	
	SET @InvOrderIDWithGrossMatch = (SELECT TOP 1 SO.OrderID FROM SalesOrders SO
								     WHERE CAST(SO.OrderDate AS DATE) <= CAST(@InvoiceDate AS DATE)
								     AND SO.CustomerID = @InvoiceCustomerID AND SO.SRID = @InvoiceSRID 
								     AND SO.SectionID = @InvoiceSectionID AND SO.GrossValue = @InvoiceGrossValue
								     ORDER BY OrderDate DESC);
								     
	SET @InvOrderID = (SELECT TOP 1 SO.OrderID FROM SalesOrders SO
				       WHERE CAST(SO.OrderDate AS DATE) <= CAST(@InvoiceDate AS DATE)
				       AND SO.CustomerID = @InvoiceCustomerID AND SO.SRID = @InvoiceSRID 
				       AND SO.SectionID = @InvoiceSectionID
				       ORDER BY OrderDate DESC);
	
	IF(ISNULL(@InvOrderIDWithGrossMatch, 0) > 0)
	BEGIN
		SET @OrderIDInsCount = ISNULL((SELECT COUNT(*) FROM @OrderIDCheck OC 
		                       WHERE OC.OrderID = @InvOrderIDWithGrossMatch), 0);
		
		IF(ISNULL(@OrderIDInsCount, 0) <= 0)
		BEGIN
			UPDATE SalesInvoices SET OrderID = @InvOrderIDWithGrossMatch
			WHERE InvoiceID = @InvoiceID;
			INSERT INTO @OrderIDCheck VALUES (@InvOrderIDWithGrossMatch);	
		END
	END
	ELSE
	BEGIN
		IF(ISNULL(@InvOrderID, 0) > 0)
		BEGIN
			SET @OrderIDInsCount = ISNULL((SELECT COUNT(*) FROM @OrderIDCheck OC 
								   WHERE OC.OrderID = @InvOrderID), 0);
		
			IF(ISNULL(@OrderIDInsCount, 0) <= 0)
			BEGIN
				UPDATE SalesInvoices SET OrderID = @InvOrderID
				WHERE InvoiceID = @InvoiceID;
				INSERT INTO @OrderIDCheck VALUES (@InvOrderID);	
			END
		END
	END
	
	FETCH NEXT FROM TmpInvoices INTO @InvoiceID, @InvoiceDate, @InvoiceCustomerID, @InvoiceSRID, @InvoiceSectionID, @InvoiceGrossValue
	SET @InnerLoop = @@FETCH_STATUS
	END
	CLOSE TmpInvoices;
	DEALLOCATE TmpInvoices;
END

FETCH NEXT FROM TmpOrdInvoices INTO @OrderID, @InvoiceCount
SET @OuterLoop = @@FETCH_STATUS
END
CLOSE TmpOrdInvoices;
DEALLOCATE TmpOrdInvoices;

DELETE FROM @OrderIDCheck;

COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK;
END CATCH

SET NOCOUNT OFF;
RETURN;