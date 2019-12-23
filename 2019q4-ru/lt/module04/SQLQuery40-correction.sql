USE [Northwind];
--4.1.2
--b)
insert dbo.Orders
	(OrderID,CustomerID,EmployeeID,ShipName,ShipCity)
select * from (values (11119, N'PERIC', 5, N'Stalin', N'Moscow'),
					   (11120, N'LILAS', 3, N'Napoleon', N'Berlin'),
					   (11121, N'VINET', 8, N'Ruzvelt', N'London'),
					   (11122, N'RICSU', 6, N'Jefferson', N'Washington'),
					   (11123, N'RICSU', 6, N'Jefferson', N'Washington') ) t1 
					   (col1,col2,col3,col4,col5);

--4.1.3

--b)
insert dbo.Orders (CustomerID, EmployeeID, OrderDate,
		RequiredDate, ShippedDate, ShipVia, Freight, ShipName, ShipAddress,
		ShipCity, ShipRegion, ShipPostalCode, ShipCountry)
select CustomerID, EmployeeID, OrderDate,
		RequiredDate, ShippedDate, ShipVia, Freight, ShipName, ShipAddress,
		ShipCity, ShipRegion, ShipPostalCode, ShipCountry from dbo.Orders ord
where CustomerID = 'WARTH' 
  and EmployeeID = 5;
  
--4.1.4
update dbo.Orders
set ShippedDate = SYSDATETIME() 
where  ShippedDate is null;

--4.1.5
update dbo.[Order Details]
set Discount = 0.11111 
where OrderID   in (select OrderId 
				    from [Orders] 
				    where CustomerID = N'GODOS')
  and ProductID in (Select ProductID 
					from dbo.Products 
					where ProductName = N'Tarte au sucre');

--4.2.2

--для другого сеанса к этой таблице нельзя обращаться ни по короткому ни по 
--полному имени, т.к. для другой сеанса наша таблица находится вне области 
--видимости.