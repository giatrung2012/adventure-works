USE AdventureWorks2019
GO

-- T có làm lại vài yêu cầu kèm đề bài

-- 1.Tạo các View
-- Yêu cầu 1: (view có điều kiện đơn giản trên 1 bảng)
-- Tính tổng trị giá của những hóa đơn với Mã theo dõi giao hàng(CarrierTrackingNumber) có 3 ký tự đầu là 4BD, thông tin bao gồm: SalesOrderID, CarrierTrackingNumber, SubTotal = SUM(OrderQty * UnitPrice)
CREATE VIEW v_TotalValueOfInvoicesWithDeliveryTrackingCode
AS
  SELECT SalesOrderID, CarrierTrackingNumber, SUM(OrderQty * UnitPrice) AS SubTotal
  FROM Sales.SalesOrderDetail
  WHERE CarrierTrackingNumber LIKE '4BD%'
  GROUP BY SalesOrderID, CarrierTrackingNumber
GO
SELECT *
FROM v_TotalValueOfInvoicesWithDeliveryTrackingCode


-- Yêu cầu 3: (gợi ý: view có điều kiện phức tạp/ truy vấn lồng trên 1 bảng)
-- Liệt kê danh sách các hóa đơn (SalesOrderID) lặp trong từ 01/05/2011 đến 31/10/2011 có tổng tiền > 100000, thông tin gồm SalesOrderID, Orderdate, SubTotal, trong đó SubTotal = SUM(OrderQty * UnitPrice).
CREATE OR ALTER VIEW v_ListDuplicateInvoices
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
FROM v_ListDuplicateInvoices


-- Yêu cầu 4: (gợi ý: view có điều kiện phức tạp/ truy vấn lồng trên 1 bảng)
-- Đếm tổng số khách hàng và tổng tiền của những khách hàng thuộc các quốc gia có mã vùng là US (lấy thông tin từ các bảng SalesTerritory, Sales.Customer, Sales.SalesOrderHeader, Sales.SalesOrderDetail). Thông tin bao gồm: tổng số khách hàng (countofCus), tổng tiền (Subtotal) với Subtotal = SUM(OrderQty * UnitPrice).
CREATE VIEW v_CountCustomer
AS
  SELECT COUNT(CustomerID) AS countofCus, SUM(SubTotal) AS TotalAmount
  FROM (
    SELECT CustomerID, SubTotal
    FROM Sales.SalesOrderHeader
    WHERE (
      SELECT COUNT(*)
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = Sales.SalesOrderHeader.SalesOrderID
    ) > 1
  ) AS t
GO
SELECT *
FROM v_CountCustomer


-- 3.Xây dựng các Function

















































-- SELECT [Status]
-- FROM Sales.SalesOrderHeader
-- select * from sales.salesorderdetail
-- select * from sales.customer
-- select * from sales.salesterritory
-- select * from sales.salesterritoryhistory
-- select * from sales.store
-- select * from sales.personquotahistory
-- select * from sales.salesperson

-- View don gian (1 bang)
CREATE VIEW v_SalesOrderHeader
AS
  SELECT *
  FROM Sales.SalesOrderHeader
  WHERE SubTotal > 3500
GO
SELECT *
FROM v_SalesOrderHeader

CREATE OR ALTER VIEW v_BusinessEntity
AS
  SELECT SP.BusinessEntityID, SUM(OrderQty) AS TotalOrderQty
  FROM Sales.SalesPerson SP, Sales.SalesOrderHeader SOH, Sales.SalesOrderDetail SOD
  WHERE SP.BusinessEntityID = SOH.SalesPersonID AND SOH.SalesOrderID = SOD.SalesOrderID
  GROUP BY SP.BusinessEntityID
GO
SELECT *
FROM v_BusinessEntity

-- create view with complex conditions/nested queries across multiple tables
DROP VIEW v_4
GO
CREATE VIEW v_4
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
FROM v_4

-- 5
UPDATE v_4
SET SubTotal = SubTotal + 100
GO
SELECT *
FROM v_4

-- 1 thủ tục không tham số
CREATE PROCEDURE sp_get_sales_person_id
AS
SELECT BusinessEntityID
FROM Sales.SalesPerson
WHERE BusinessEntityID > 280
GO
EXEC sp_get_sales_person_id

-- 1 thủ tục có tham số mặc định
CREATE PROCEDURE sp_get_sales_person_id_default
  @BusinessEntityID INT = 280
AS
SELECT BusinessEntityID
FROM Sales.SalesPerson
WHERE BusinessEntityID = @BusinessEntityID
GO
EXEC sp_get_sales_person_id_default

-- thủ tục có tham số input [1]
CREATE PROCEDURE sp_get_sales_person_id_input
  @BusinessEntityID INT
AS
SELECT *
FROM Sales.SalesPerson
WHERE BusinessEntityID = @BusinessEntityID
GO
EXEC sp_get_sales_person_id_input @BusinessEntityID = 282

-- write code create proc with input in 2 table and have 2 parameters
CREATE PROC sp_get_sales_person_id_input_2_table
  @BusinessEntityID INT,
  @SalesOrderID INT
AS
SELECT *
FROM Sales.SalesPerson
WHERE 
GO
EXEC sp_get_sales_person_id_input_2_table @BusinessEntityID = 282, @SalesOrderID = 1

-- hàm trả về kiểu vô hướng [1]
CREATE OR ALTER FUNCTION fn_get_sales_person_bonus(@ID INT)
RETURNS INT
AS
BEGIN
  RETURN (SELECT Bonus
  FROM Sales.SalesPerson
  WHERE BusinessEntityID = @ID)
END
GO
PRINT dbo.fn_get_sales_person_bonus(283)

-- hàm trả về kiểu vô hướng [2]
CREATE OR ALTER FUNCTION fn_get_sales_customer_account_number(@ID INT)
RETURNS VARCHAR(10)
AS
BEGIN
  RETURN (SELECT AccountNumber
  FROM Sales.Customer
  WHERE CustomerID = @ID)
END
GO
PRINT dbo.fn_get_sales_customer_account_number(3)

-- write code create function return table with table sales.salesorderdetail
CREATE OR ALTER FUNCTION fn_get_sales_order_detail(@ID INT)
RETURNS TABLE
AS
BEGIN
  RETURN (SELECT *
  FROM Sales.SalesOrderDetail
  WHERE SalesOrderID = @ID)
END
GO
SELECT *
FROM fn_get_sales_order_detail(1)

















