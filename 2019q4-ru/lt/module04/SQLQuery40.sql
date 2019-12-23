USE [Northwind]
--4.1.1
--a)
SET IDENTITY_INSERT dbo.Orders ON
insert dbo.Orders
	(OrderID,CustomerID,EmployeeID,ShipName,ShipCity)
values
	(11111, N'VINET', 8, N'VivaVictoria', N'Piter')

Select * from dbo.Orders;
--b)
insert dbo.Orders
	(OrderID,ShipName,ShipCity)
select
	11112, N'Putnik', N'Piterbugrskiy'

--4.1.2
--a)
SET IDENTITY_INSERT dbo.Orders ON
insert dbo.Orders
	(OrderID,CustomerID,EmployeeID,ShipName,ShipCity)
values
	(11113, N'VINET', 2, N'Cherchil', N'London'),
	(11114, N'PERIC', 5, N'Stalin', N'Moscow'),
	(11115, N'LILAS', 3, N'Napoleon', N'Berlin'),
	(11116, N'VINET', 8, N'Ruzvelt', N'London'),
	(11117, N'RICSU', 6, N'Jefferson', N'Washington')
--b)
insert dbo.Orders
	(OrderID,CustomerID,EmployeeID,ShipName,ShipCity)
select * from (values (11119, N'PERIC', 5, N'Stalin', N'Moscow'),
					   (11120, N'LILAS', 3, N'Napoleon', N'Berlin'),
					   (11121, N'VINET', 8, N'Ruzvelt', N'London'),
					   (11122, N'RICSU', 6, N'Jefferson', N'Washington'),
					   (11123, N'RICSU', 6, N'Jefferson', N'Washington') ) t1 (col1,col2,col3,col4,col5) where 1=1;

--4.1.3
--a)
SET IDENTITY_INSERT dbo.Orders OFF
insert dbo.Orders
	(CustomerID,EmployeeID)
values
	(N'WARTH', 5)
select * from dbo.Orders
--b)
SET IDENTITY_INSERT dbo.Orders OFF
insert dbo.Orders
	(CustomerID,EmployeeID)
values
	(N'TOMSP', 5)
select * from dbo.Orders

--4.1.4
--не пон€л, что значит еще не доставлены, если как € понимаю доставлены все.
--ќбновил те, которые были доставлены с опозданием.
update dbo.Orders
set ShippedDate = SYSDATETIME() where RequiredDate < ShippedDate

--4.1.5
update dbo.[Order Details]
set Discount = 0.11111 where OrderID in (select OrderId from [Orders] where CustomerID = 'GODOS')
and ProductID in (Select ProductID from dbo.Products where ProductName = 'Tarte au sucre')

--4.1.6
delete from dbo.[Order Details] 
where UnitPrice < 20

--4.2.1
--a)
Create table #tblBook (BookID int NOT NULL, 
					   Name char(35))
insert #tblBook values (1, 'War and peace'),
					   (2, 'Crime and punishment'),
					   (3, 'The master and Margarita'),
					   (4, 'Quiet Don')
--select * from #tblBook
drop table #tblBook
--b)
Create table #tblBookInLibrary (BookID int NOT NULL, 
								Date Date)
insert #tblBookInLibrary values (1, '01.05.2006'),
								(2, '05.07.2004')

--«апрос 1
select #tblBook.BookID, Name, Date from #tblBook join #tblBookInLibrary
		on (#tblBook.BookID = #tblBookInLibrary.BookID)
		where Date > '01.02.2005';
--«апрос 2
select #tblBook.BookID, Name from #tblBook left join #tblBookInLibrary
		on (#tblBook.BookID = #tblBookInLibrary.BookID)
		where Date > '01.02.2005' or Date is NULL;

--Bз другого сеанса к этой таблице нельз€ обращатьс€ ни по короткому ни по 
--полному имени, т.к. дл€ другой сеанса наша таблица находитс€ вне области 
--видимости.