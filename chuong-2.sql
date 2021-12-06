USE AdventureWorks2019
GO

-- 1.Tạo các View
-- Yêu cầu 1: (view có điều kiện đơn giản trên 1 bảng)
-- Tạo view tính tổng trị giá của những hóa đơn với Mã theo dõi giao hàng(CarrierTrackingNumber) có 3 ký tự đầu là 4BD, thông tin bao gồm: SalesOrderID, CarrierTrackingNumber, SubTotal = SUM(OrderQty * UnitPrice)
CREATE VIEW v_TotalValueOfInvoices
AS
  SELECT SalesOrderID, CarrierTrackingNumber, SUM(OrderQty * UnitPrice) AS SubTotal
  FROM Sales.SalesOrderDetail
  WHERE CarrierTrackingNumber LIKE '4BD%'
  GROUP BY SalesOrderID, CarrierTrackingNumber
GO
SELECT *
FROM v_TotalValueOfInvoices


-- Yêu cầu 2: (gợi ý: view có điều kiện đơn giản trên nhiều bảng)
-- Tạo View hiển thị top 5 tổng doanh số cao nhất từ cột TotalDue mỗi năm và mỗi tháng cho từng khách hàng.
CREATE VIEW vw_CustomerTotals 
AS
  SELECT TOP 5 C.CustomerID, YEAR(OrderDate) AS OrderYear, MONTH(OrderDate) AS OrderMonth, SUM(TotalDue) AS TotalSales
  FROM Sales.Customer C, Sales.SalesOrderHeader SOH
  WHERE C.CustomerID = SOH.CustomerID
  GROUP BY C.CustomerID, YEAR(OrderDate), MONTH(OrderDate)
  ORDER BY TotalSales DESC
GO
SELECT *
FROM vw_CustomerTotals


-- Yêu cầu 3: (gợi ý: view có điều kiện phức tạp/ truy vấn lồng trên 1 bảng)
-- Tạo View liệt kê danh sách các hóa đơn (SalesOrderID) lặp trong từ 01/05/2011 đến 31/10/2011 có tổng tiền > 100000, thông tin gồm SalesOrderID, Orderdate, SubTotal, trong đó SubTotal = SUM(OrderQty * UnitPrice).
CREATE VIEW vw_ListDuplicateInvoices
AS
  SELECT SalesOrderID, OrderDate, SubTotal
  FROM Sales.SalesOrderHeader
  WHERE (OrderDate BETWEEN '2011-05-01' AND '2011-10-31')
    AND SubTotal > 100000
    AND (
      SELECT COUNT(*)
      FROM Sales.SalesOrderDetail
      WHERE SalesOrderID = Sales.SalesOrderHeader.SalesOrderID
    ) > 1
GO
SELECT *
FROM vw_ListDuplicateInvoices


-- Yêu cầu 4: (gợi ý: view có điều kiện phức tạp/ truy vấn lồng trên 1 bảng)
-- Tạo View hiển thị danh sách các hóa đơn có SubTotal (Tổng phụ bán hàng) > 3500 và có hơn 70 loại sản phẩm.
CREATE VIEW vw_ListInvoicesHaveLotsOfProducts
AS
  SELECT *
  FROM Sales.SalesOrderHeader
  WHERE SubTotal > 3500
    AND (
      SELECT COUNT(*)
      FROM Sales.SalesOrderDetail
      WHERE SalesOrderID = Sales.SalesOrderHeader.SalesOrderID
    ) > 70
GO
SELECT *
FROM vw_ListInvoicesHaveLotsOfProducts


-- Yêu cầu 5: view cập nhật dữ liệu
-- Nhận thấy SubTotal trong các hóa đơn khá cao, tặng nhẹ 10% thuế (TaxAmt) cho hóa đơn có SubTotal cao nhất ngay trên View vw_ListInvoicesHaveLotsOfProducts.
SELECT TOP 1 SalesOrderID, SubTotal, TaxAmt
FROM vw_ListInvoicesHaveLotsOfProducts
ORDER BY SubTotal DESC
GO
UPDATE vw_ListInvoicesHaveLotsOfProducts
SET TaxAmt *= 1.1
WHERE SubTotal = (
  SELECT MAX(SubTotal)
  FROM vw_ListInvoicesHaveLotsOfProducts
)
GO
SELECT TOP 1 SalesOrderID, SubTotal, TaxAmt
FROM vw_ListInvoicesHaveLotsOfProducts
ORDER BY SubTotal DESC


-- 2.Xây dựng các Stored procedure
-- Yêu cầu 1: Viết thủ tục lấy ra tiền thưởng cao nhất của trong bảng Sales.SalesPerson.
CREATE PROC sp_GetMaxBonus
AS
  SELECT MAX(Bonus) AS MaxBonus
  FROM Sales.SalesPerson
GO
EXEC sp_GetMaxBonus


---1 thủ tục có tham số mặc định
-- Yêu cầu 2: Viết thủ tục có tham số mặc định là @ID = 274 lấy ra tổng số lượng hạn ngạch bán hàng (TotalSalesQuota) của ID đó.
CREATE PROC sp_GetTotalSalesQuota
  @ID INT = 274
AS
  SELECT BusinessEntityID, SUM(SalesQuota) AS TotalSalesQuota
  FROM Sales.SalesPersonQuotaHistory
  WHERE BusinessEntityID = @ID
  GROUP BY BusinessEntityID
GO
EXEC sp_GetTotalSalesQuota


-- 1 thủ tục có tham số output
-- Yêu cầu 3: Viết thủ tục có tham số output là @Count, khi người dùng truyền vào mã quốc gia thì hiển thị thông tin và đếm số lượng lãnh thổ thuộc quốc gia đó.
CREATE PROC sp_CountTerritory
@Code VARCHAR(2),
@TerritoryCount INT OUTPUT
AS
BEGIN
SELECT *
FROM Sales.SalesTerritory
WHERE CountryRegionCode = @Code

SET @TerritoryCount = @@ROWCOUNT
END
GO
DECLARE @Count INT
EXEC sp_CountTerritory 'AU', @Count OUTPUT
SELECT @Count AS NumberOfTerritory


-- 2 thủ tục có tham số input (4, 5)
-- Yêu cầu 4: Viết một thủ tục tính tổng tiền thu (TotalDue) của mỗi khách hàng trong một tháng bất kỳ của một năm bất kỳ (tham số tháng và năm) được nhập từ bàn phím, thông tin gồm: CustomerID, SumofTotalDue = Sum(TotalDue)
CREATE PROC sp_SumOfTotalDue
  (@CustomerID INT, @Year INT, @Month INT)
AS
BEGIN
	SELECT CustomerID, SUM(TotalDue) AS SumOfTotalDue
	FROM Sales.SalesOrderHeader
	WHERE CustomerID = @CustomerID
		AND YEAR(OrderDate) = @Year
		AND MONTH(OrderDate) = @Month
	GROUP BY CustomerID
END
GO
EXEC sp_SumOfTotalDue 29825, 2011, 5

-- Yêu cầu 5: Tạo thủ tục Đếm tổng số khách hàng và tổng tiền của những khách hàng khi người dùng nhập mã quốc gia (lấy thông tin từ các bảng SalesTerritory, Sales.Customer, Sales.SalesOrderHeader, Sales.SalesOrderDetail).Thông tin bao gồm TerritoryID, tổng số khách hàng (countofCus), tổng tiền (Subtotal) với Subtotal = SUM(OrderQty*UnitPrice)
CREATE PROC sp_CountCustomer
@Code VARCHAR(2)
AS
BEGIN
  SELECT ST.TerritoryID, COUNT(C.CustomerID) AS NumberOfCustomer, SUM(Subtotal) AS SumOfSubtotal
  FROM Sales.Customer C, Sales.SalesOrderHeader SOH, Sales.SalesOrderDetail SOD, Sales.SalesTerritory ST
  WHERE CountryRegionCode = @Code
    AND C.CustomerID = SOH.CustomerID
    AND SOH.SalesOrderID = SOD.SalesOrderID
    AND SOH.TerritoryID = ST.TerritoryID
  GROUP BY ST.TerritoryID
END
GO
EXEC sp_CountCustomer 'AU'


-- 3.Xây dựng các Function
-- hàm trả về kiểu vô hướng [1]
-- Yêu cầu 1: Viết hàm trả về biểu diễn văn bản của cột Status trong bảng SalesOrderHeader. 
CREATE FUNCTION fn_GetSalesOrderStatusText(@Status TINYINT)
RETURNS VARCHAR(15) 
AS 
BEGIN
  DECLARE @Result VARCHAR(15)
  SET @Result = (
    CASE @Status
      WHEN 1 THEN 'In process'
      WHEN 2 THEN 'Approved'
      WHEN 3 THEN 'Backordered'
      WHEN 4 THEN 'Rejected'
      WHEN 5 THEN 'Shipped'
      WHEN 6 THEN 'Cancelled'
      ELSE '** Invalid **'
    END
  )
  RETURN @Result
END
GO
PRINT 'SalesOrderStatus: ' + dbo.fn_GetSalesOrderStatusText(5)


-- Viết hàm tên Discount_func tính số tiền giảm trên các hóa đơn
-- (SalesOrderID), thông tin gồm SalesOrderID, [SubTotal], Discount, trong đó,
-- Discount được tính như sau:
-- [SubTotal]<1000 thì Discount=0
-- 1000>=[SubTotal]<5000 thì Discount = 5%[SubTotal]
-- case
-- when SubTotal<1000
-- then 0
-- when
-- SubTotal>=1000 and
-- SubTotal<5000 then
-- [SubTotal]*0.05
-- when
-- SubTotal>=5000 and
-- SubTotal<10000
-- then
-- [SubTotal]*0.1
-- else SubTotal*0.15
-- end

-- 5000>=[SubTotal]<10000 thì Discount =
-- 10%[SubTotal]
-- [SubTotal>=10000 thì Discount = 15%
-- [SubTotal]
CREATE or alter FUNCTION dbo.fn_GetDiscountAmount(@SalesOrderID INT)
RETURNS MONEY
AS
BEGIN
  DECLARE @SubTotal MONEY
  DECLARE @Discount MONEY

  SELECT @SubTotal = SubTotal
  FROM Sales.SalesOrderHeader
  WHERE SalesOrderID = @SalesOrderID
  
  SET @Discount = (
    CASE
      WHEN @SubTotal < 1000 THEN 0
      WHEN @SubTotal >= 1000 AND @SubTotal < 5000 THEN @SubTotal * 0.05
      WHEN @SubTotal >= 5000 AND @SubTotal < 100000 THEN @SubTotal * 0.1
      WHEN @SubTotal >= 100000 THEN @SubTotal * 0.15
    END
  )
  RETURN @Discount
END
GO
PRINT 'DiscountAmount: ' + CONVERT(VARCHAR(20), dbo.fn_GetDiscountAmount(43659))


-- hàm trả về bảng [1]
-- Write a function with two parameters @Month and @Year that returns a list of invoices (SalesOrderID) repeated in the month and year passed from 2 parameters @Month and @Year, with total amount > 100000, information includes: SalesOrderID , Orderdate, SubTotal, where SubTotal
CREATE or alter FUNCTION dbo.fn_GetInvoiceList
  (@Month INT, @Year INT)
RETURNS TABLE
AS
RETURN (
  SELECT SalesOrderID, OrderDate, SubTotal
  FROM Sales.SalesOrderHeader
  WHERE YEAR(OrderDate) = @Year
    AND MONTH(OrderDate) = @Month
  GROUP BY SalesOrderID, OrderDate, SubTotal
)
GO
SELECT * FROM fn_GetInvoiceList(5, 2011)


-- hàm trả về bảng [2]
-- Write a function with parameters @MonthOrder, @YearOrder to calculate the total sales of salespeople (SalePerson) in the month and year passed and 2 parameters, information includes [SalesPersonID], Total, with Total = SUM(SubTotal )
CREATE or alter FUNCTION dbo.fn_GetSalesPersonTotal
  (@MonthOrder INT, @YearOrder INT)
RETURNS TABLE
AS
RETURN (
  SELECT SalesPersonID, SUM(SubTotal) AS Total
  FROM Sales.SalesOrderHeader
  WHERE YEAR(OrderDate) = @YearOrder
    AND MONTH(OrderDate) = @MonthOrder
    AND SalesPersonID IS NOT NULL
  GROUP BY SalesPersonID
)
GO
SELECT * FROM fn_GetSalesPersonTotal(7, 2011)


-- ham tra ve bang tu dinh nghia
--



-- 4.Xây dựng các Trigger và Transaction
-- 1 Trigger Insert, …
-- Tạo trigger cập nhật tiền thưởng (Bonus) cho nhân viên bán hàng SalesPerson, khi người dùng chèn thêm một record mới trên bảng SalesOrderHeader, theo quy định như sau: Nếu tổng tiền bán được của nhân viên có hóa đơn mới nhập vào bảng SalesOrderHeader có giá trị > 10000000 thì tăng tiền thưởng lên 10% của mức thưởng hiện tại.
CREATE TRIGGER t_Bonus_Insert
ON Sales.SalesOrderHeader
FOR INSERT
AS
BEGIN
  DECLARE @ID INT = (SELECT SalesPersonID FROM inserted)
  DECLARE @Total MONEY = (SELECT SubTotal FROM inserted)
  IF @Total > 10000000
  BEGIN
    UPDATE Sales.SalesPerson
    SET Bonus = Bonus + @Total * 0.1
    WHERE BusinessEntityID = @ID
  END
END


-- 1 Trigger Update, …
-- Tạo trigger khi cập nhật bảng Sales.SalesTerritory thì cập nhật lại bảng Sales.SalesTerritoryHistory với TerritoryID mới và StartDate là ngày hiện tại.
CREATE TRIGGER t_Update_SalesTerritory
ON Sales.SalesTerritory
FOR UPDATE
AS
BEGIN
  DECLARE @OldID INT = (SELECT TerritoryID FROM deleted)
  DECLARE @NewID INT = (SELECT TerritoryID FROM inserted)

  UPDATE Sales.SalesTerritoryHistory
  SET EndDate = GETDATE()
  WHERE TerritoryID = @OldID
  
  INSERT INTO Sales.SalesTerritoryHistory
    (StartDate, TerritoryID)
  VALUES
    (GETDATE(), @NewID)
END


-- 1 Trigger Delete, …
-- Viết trigger dùng để xóa hóa đơn trong bảng Sales.SalesOrderHeader, đồng thời xóa các bản ghi của hóa đơn đó trong Sales.SalesOrderDetail. Nếu không tồn tại hóa đơn trong Sales.SalesOrderHeader, thì không được phép xóa hóa đơn đó trong Sales.SalesOrderDetail và in thông báo lỗi.
CREATE TRIGGER sales.t_DeleteInvoice
ON Sales.SalesOrderHeader
FOR DELETE
AS
BEGIN
  DECLARE @ID INT = (SELECT SalesOrderID FROM deleted)
  IF NOT EXISTS (
    SELECT * 
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @ID
  )
  BEGIN
    PRINT 'Invoice does not exist'
    ROLLBACK
  END
  ELSE
  BEGIN
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @ID
  END
END


-- 2 Transaction (COMMIT và ROLL BACK)
-- Transaction DeleteSomethings dùng để xóa liên tục nhiều bản ghi trên nhiều bảng khác nhau. Nếu có câu lệnh trong Transaction thất bại thì in ra lỗi sau đó ROLLBACK, ngược lại thì COMMIT.
BEGIN TRAN DeleteSomethings
BEGIN TRY
	DELETE FROM Sales.Store WHERE Name = 'South Bike Company'
	DELETE FROM Sales.SalesPerson WHERE BusinessEntityID = 1
	DELETE FROM Sales.SalesTerritory WHERE Name = 'North'
  PRINT 'Success'
	COMMIT
END TRY
BEGIN CATCH
	PRINT N'Can not delete'
	ROLLBACK
END CATCH


-- Transaction InsertSomethings dùng để thêm liên tục nhiều bản ghi trên nhiều bảng khác nhau. Nếu có câu lệnh trong Transaction thất bại thì in ra lỗi sau đó ROLLBACK, ngược lại thì COMMIT.
BEGIN TRAN InsertSomethings
BEGIN TRY
	INSERT INTO Sales.SalesTerritory
    (Name, rowguid, ModifiedDate)
  VALUES
    ('South', NEWID(), GETDATE())
	INSERT INTO Sales.SalesPerson
    (BusinessEntityID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear, rowguid, ModifiedDate)
  VALUES
    (3, 1000, 0, 0.1, 1000, 1000, NEWID(), GETDATE())
  PRINT 'Success'
	COMMIT
END TRY
BEGIN CATCH
	PRINT N'Can not insert'
  ROLLBACK
END CATCH


-- 5.Tạo các user
-- Tạo User HuanHoaHong cho bảng Sales.SalePerson hhh có quyền Thêm, chỉnh sửa dữ liệu
CREATE LOGIN Karik WITH PASSWORD = 'forget2C@n'
GO
CREATE USER k FOR LOGIN HoanHoaHong
GO
GRANT INSERT,UPDATE ON Sales.SalesPerson TO k


-- Tạo User TranDan cho bảng Sales.Store td có quyền xem dữ liệu
CREATE LOGIN Wowy WITH PASSWORD = 'Mercedesm@ux@nh'
GO
CREATE USER w FOR LOGIN TranDan
GO
GRANT SELECT ON Sales.SalesPerson TO w
