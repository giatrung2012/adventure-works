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
CREATE FUNCTION fn_get_sales_person_bonus(@ID INT)
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
CREATE FUNCTION fn_get_sales_customer_account_number(@ID INT)
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
CREATE OR FUNCTION fn_get_sales_order_detail(@ID INT)
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


select * from sales.store