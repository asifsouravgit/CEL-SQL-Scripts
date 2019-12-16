
DECLARE @SalesPointID INT = 5, @StartDate DATETIME = '1 JUL 2019', @EndDate DATETIME = '31 JUL 2019';

SELECT M.SalesDate, M.SalesPointID, M.SRID, M.SectionID, M.RouteID, M.SKUID,
SUM(M.GrossSalesQtyRegular) GrossSalesQtyRegular, SUM(M.GrossSalesValueRegular) GrossSalesValueRegular,
SUM(M.FreeSalesQtyRegular) FreeSalesQtyRegular, SUM(M.FreeSalesValueRegular) FreeSalesValueRegular, 
SUM(M.DiscountRegular) DiscountRegular, SUM(M.GrossSalesQtyB2B) GrossSalesQtyB2B, SUM(M.GrossSalesValueB2B) GrossSalesValueB2B, 
SUM(M.FreeSalesQtyB2B) FreeSalesQtyB2B,SUM(M.FreeSalesValueB2B) FreeSalesValueB2B, SUM(M.DiscountB2B) DiscountB2B

FROM 
(
	SELECT A.InvoiceDate SalesDate, A.SalesPointID, A.SRID, A.SectionID, A.RouteID, B.SKUID, 
	SUM(B.Quantity + B.FreeQty) GrossSalesQtyRegular, SUM((B.Quantity + B.FreeQty) * B.TradePrice) GrossSalesValueRegular,
	SUM(B.FreeQty) FreeSalesQtyRegular, SUM(B.FreeQty * B.TradePrice) FreeSalesValueRegular, 
	SUM(B.DiscountRate + B.SpecialDiscount) DiscountRegular, 
	0 GrossSalesQtyB2B, 0 GrossSalesValueB2B, 0 FreeSalesQtyB2B, 0 FreeSalesValueB2B, 0 DiscountB2B
	FROM SalesInvoices A INNER JOIN SalesInvoiceItem B ON B.InvoiceID = A.InvoiceID
	WHERE A.SalesPointID = @SalesPointID AND A.SalesType <> 9
	AND CAST(A.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)
	GROUP BY A.InvoiceDate, A.SalesPointID, A.SRID, A.SectionID, A.RouteID, B.SKUID

	UNION

	SELECT A.InvoiceDate SalesDate, A.SalesPointID, A.SRID, A.SectionID, A.RouteID, B.SKUID, 
	0 GrossSalesQtyRegular, 0 GrossSalesValueRegular, 0 FreeSalesQtyRegular, 0 FreeSalesValueRegular, 0 DiscountRegular, 
	SUM(B.Quantity + B.FreeQty) GrossSalesQtyB2B, SUM((B.Quantity + B.FreeQty) * B.TradePrice) GrossSalesValueB2B, 
	SUM(B.FreeQty) FreeSalesQtyB2B, SUM(B.FreeQty * B.TradePrice) FreeSalesValueB2B, SUM(B.DiscountRate + B.SpecialDiscount) DiscountB2B
	FROM SalesInvoices A INNER JOIN SalesInvoiceItem B ON B.InvoiceID = A.InvoiceID
	WHERE A.SalesPointID = @SalesPointID AND A.SalesType = 9
	AND CAST(A.InvoiceDate AS DATE) BETWEEN CAST(@StartDate AS DATE) AND CAST(@EndDate AS DATE)
	GROUP BY A.InvoiceDate, A.SalesPointID, A.SRID, A.SectionID, A.RouteID, B.SKUID
) M
GROUP BY M.SalesDate, M.SalesPointID, M.SRID, M.SectionID, M.RouteID, M.SKUID


