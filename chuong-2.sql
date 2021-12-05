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
-- 1 thủ tục không tham số
-- Thủ tục 1:
-- Write a procedure to calculate the total amount (TotalDue) of each customer in a
-- any month of any year (month and year parameters) are entered from the table
-- key, information includes: CustomerID, SumofTotalDue =Sum(TotalDue)
-- 1. Tạo stored procedure v_SumOfTotalDue
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




---1 thủ tục có tham số mặc định
-- Thủ tục 2: yêu cầu

-- 1 thủ tục có tham số output

-- 2 thủ tục có tham số input
-- (có thể xây dựng hàm sau đó dùng Thủ tục để gọi hàm)




-- 3.Xây dựng các Function
-- hàm trả về kiểu vô hướng [1]
-- Hàm 
-- CREATE or alter FUNCTION dbo.fn_GetAccountingEndDate()
-- RETURNS DATETIME 
-- AS 
-- BEGIN
--   RETURN DATEADD(MILLISECOND, -2, '2012-12-21')
-- END
-- GO
-- PRINT dbo.fn_GetAccountingEndDate()

-- SELECT CONVERT (time, SYSDATETIME()) ,CONVERT (time, SYSDATETIMEOFFSET())
-- ,CONVERT (time, SYSUTCDATETIME())
-- ,CONVERT (time, CURRENT_TIMESTAMP)
-- ,CONVERT (time, GETDATE())
-- ,CONVERT (time, GETUTCDATE());


-- print convert(datetime, SYSDATETIME())

-- hàm trả về bảng [1]
-- Viết hàm sumofOrder với hai tham số @Month và @Year trả về danh sách các hóa đơn (SalesOrderID) lặp trong tháng và năm được truyền vào từ 2 tham số @Month và @Year, có tổng tiền > 100000, thông tin gồm: SalesOrderID, Orderdate, SubTotal, trong đó SubTotal = SUM(OrderQty * UnitPrice).
CREATE FUNCTION sumofOrder(@Month INT, @Year INT)
RETURNS TABLE
AS
RETURN (
  SELECT SOH.SalesOrderID, OrderDate, SUM(OrderQty * UnitPrice) AS SubTotal
  FROM Sales.SalesOrderHeader SOH, Sales.SalesOrderDetail SOD
  WHERE SOH.SalesOrderID = SOD.SalesOrderID 
    AND MONTH(OrderDate) = @Month 
    AND YEAR(OrderDate) = @Year AND SubTotal > 100000 
  GROUP BY SOH.SalesOrderID, OrderDate
)
GO
SELECT *
FROM sumofOrder(10, 2011)


-- hàm trả về bảng [2]
-- Viết hàm TotalOfEmp với tham số @MonthOrder, @YearOrder để tính tổng doanh thu của các nhân viên bán hàng (SalePerson) trong tháng và năm được truyền và 2 tham số, thông tin gồm [SalesPersonID], Total, với Total = SUM(SubTotal)
CREATE FUNCTION TotalOfEmp(@MonthOrder INT, @YearOrder INT)
RETURNS TABLE
AS
RETURN (
  SELECT SOH.SalesPersonID, SUM(SOD.OrderQty * SOD.UnitPrice) AS Total 
  FROM Sales.SalesOrderHeader SOH, Sales.SalesOrderDetail SOD 
  WHERE SOH.SalesOrderID = SOD.SalesOrderID 
    AND MONTH(OrderDate) = @MonthOrder
    AND YEAR(OrderDate) = @YearOrder
    AND SOH.SalesPersonID IS NOT NULL
  GROUP BY SOH.SalesPersonID
)
GO
SELECT *
FROM TotalOfEmp(7, 2011)


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




-- SELECT [Status]
-- FROM Sales.SalesOrderHeader
-- select * from sales.salesorderdetail
-- select * from sales.customer
-- select * from sales.salesterritory
-- select * from sales.salesterritoryhistory
-- select * from sales.store
-- select * from sales.personquotahistory
-- select * from sales.salesperson
