USE Northwind;

--5.1
--первый запрос с использованием аналитических функций.
GO
CREATE PROCEDURE GreatestOrders (@Year int, @Limit int) AS
select top (@Limit) * from (
	select top(1) with employees * from (
		select emp.FirstName, 
			   emp.LastName, 
			   ord.OrderID, 
			   SUM(UnitPrice*Quantity*(1-Discount)) as OrderPrice 
		from dbo.[Order Details] ordd
			join dbo.Orders ord
			on (ordd.OrderID = ord.OrderID)
			join dbo.Employees emp
			on (ord.EmployeeID = emp.EmployeeID)
		where year(ord.OrderDate) = @Year
		group by ord.OrderID, emp.FirstName, emp.LastName) as PriceTable
	order by rank() over (partition by FirstName, LastName order by OrderPrice desc)) as MaxPriceTable
order by OrderPrice desc;

DROP PROCEDURE GreatestOrders; 

--Первый запрос без аналитических функций
go
create procedure GreatestOrders (@Year int, @Limit int) AS
select top (@Limit) emp.FirstName, emp.LastName, o.OrderID, OrdersSum.OrderPrice
from dbo.Orders o
join 
	(select ord.OrderID, sum(UnitPrice*Quantity*(1-Discount)) OrderPrice
	from dbo.[Order Details] ordd
	join dbo.Orders ord
	on(ord.OrderID = ordd.OrderID)
	where year(ord.OrderDate) = @Year 
	group by ord.OrderID
	) as OrdersSum
on (o.OrderID = OrdersSum.OrderID)
join dbo.Employees emp
on (o.EmployeeID = emp.EmployeeID)
where o.OrderID in 
	(select top (1) ord.OrderID
	from dbo.[Order Details] ordd
	join dbo.Orders ord
	on(ord.OrderID = ordd.OrderID)
	where year(ord.OrderDate) = @Year 
	and ord.EmployeeID = o.EmployeeID
	group by ord.OrderID
	order by sum(UnitPrice*Quantity*(1-Discount)) desc
	)
order by OrderPrice desc

exec dbo.GreatestOrders 1997, 6

--Проверочная функция
select top 4 * from (
select top(1) with ties * from (
select dbo.Employees.FirstName, dbo.Employees.LastName, dbo.Orders.OrderID, SUM(UnitPrice*Quantity*(1-Discount)) as OrderPrice from dbo.[Order Details] join dbo.Orders
	on (dbo.[Order Details].OrderID = dbo.Orders.OrderID)
	join dbo.Employees
	on (dbo.Orders.EmployeeID = dbo.Employees.EmployeeID)
where year(dbo.Orders.OrderDate) = 1996
group by dbo.Orders.OrderID, dbo.Employees.FirstName, dbo.Employees.LastName) as PriceTable
order by rank() over (partition by FirstName, LastName order by OrderPrice desc)) as MaxPriceTable
order by OrderPrice desc

select year(OrderDate) from dbo.Orders



--use kursors

go
create procedure GreatestOrdersCur (@Year int, @Limit int) AS

DECLARE @FirstName nvarchar(50), @LastName nvarchar(50), @EmployeeID int
declare Employee_cur cursor for 
select FirstName, LastName, EmployeeID from dbo.Employees;

CREATE TABLE #EmployeesOrders
(
	FirstName VARCHAR(50),
	LastName VARCHAR(50),
	OrderID int,
	OrdersSum int
)

open Employee_cur

fetch next from Employee_cur
into @FirstName, @LastName, @EmployeeID

while @@fetch_status = 0
begin
	insert into #EmployeesOrders
	select emp.FirstName, emp.LastName, o.OrderID, OrdersSum.OrderPrice
	from dbo.Orders o
	join 
		(select ord.OrderID, sum(UnitPrice*Quantity*(1-Discount)) OrderPrice
		from dbo.[Order Details] ordd
		join dbo.Orders ord
		on(ord.OrderID = ordd.OrderID)
		where year(ord.OrderDate) = @Year 
		group by ord.OrderID
		) as OrdersSum
	on (o.OrderID = OrdersSum.OrderID)
	join dbo.Employees emp
	on (o.EmployeeID = emp.EmployeeID)
	where o.OrderID in 
		(select top (1) ord.OrderID
		from dbo.[Order Details] ordd
		join dbo.Orders ord
		on(ord.OrderID = ordd.OrderID)
		where year(ord.OrderDate) = @Year 
		and ord.EmployeeID = @EmployeeID
		group by ord.OrderID
		order by sum(UnitPrice*Quantity*(1-Discount)) desc
		)
	FETCH NEXT FROM Employee_cur into @FirstName, @LastName, @EmployeeID
end
select top (@Limit) * from #EmployeesOrders
order by #EmployeesOrders.OrdersSum desc
close Employee_cur;
drop table #EmployeesOrders
deallocate Employee_cur;  

exec dbo.GreatestOrdersCur 1997, 6

--5.2
go
create procedure ShippedOrdersDiff (@Delay int = 35) AS
select ord.OrderID, 
	   ord.OrderDate, 
	   ord.ShippedDate, 
	   DATEDIFF(dd, 0, ord.ShippedDate - ord.OrderDate) as ShippedDelay,
	   @Delay as SpecifiedDelay 
from dbo.Orders ord
where DATEDIFF(dd, 0, ShippedDate - OrderDate) > @Delay;

exec dbo.ShippedOrdersDiff 10;

--5.3


go
create function IsBoss (@EmployeeID int)
returns bit  
as
begin
     declare @Boss bit = 0;  
     if (@EmployeeID in (select emp.ReportsTo from dbo.Employees emp) or
		 @EmployeeID is null)
			set @Boss = 1;
     return(@Boss);  
end;

select dbo.IsBoss (5);

-- 5.4

go
create view OrdersInfo as
select ord.OrderID, ord.CustomerID, emp.FirstName, emp.LastName, ord.OrderDate, ord.RequiredDate, prod.ProductName, ordd.UnitPrice*ordd.Quantity*(1-ordd.Discount) as ProductPrice
from dbo.Orders ord
join dbo.Employees emp
on (ord.EmployeeID = emp.EmployeeID)
join dbo.[Order Details] ordd
on (ord.OrderID = ordd.OrderID)
join dbo.Products prod
on (ordd.ProductID = prod.ProductID);

select * from dbo.OrdersInfo;

--5.5

create table OrdersHistory (
  HistoryId int Identity(1,1),
  [OrderID] int,
  [CustomerID] nvarchar(5) null,
  [EmployeeID] int null,
  [OrderDate] datetime null,
  [RequiredDate]  datetime null,
  [ShippedDate]  datetime null,
  [ShipVia]  int null,
  [Freight]  money null,
  [ShipName] nvarchar(40) null,
  [ShipAddress]  nvarchar(60) null,
  [ShipCity]  nvarchar(15) null,
  [ShipRegion]  nvarchar(15) null,
  [ShipPostalCode]  nvarchar(10) null,
  [ShipCountry] nvarchar(15) null,
  ChangesType nvarchar(15) null,
  ChangedByUser nvarchar(50) null,
  ChangesTime Datetime
);
go

select * from dbo.OrdersHistory;

go
create trigger OrdersTrigger
on dbo.Orders 
after insert, update, delete
as
	set nocount on;
	
	declare @change_type as varchar(10)
	declare @count as int
	set @change_type = 'inserted'
	select @count = COUNT(*) FROM DELETED
	if @count > 0
	begin
		set @change_type = 'deleted'
		select @count = COUNT(*) from INSERTED
		if @Count > 0
			set @change_type = 'updated'
	end
	if @change_type = 'deleted'
		begin
			insert into dbo.OrdersHistory(OrderID, CustomerID, EmployeeID, OrderDate,
				RequiredDate, ShippedDate, ShipVia, Freight, ShipName, ShipAddress,
				ShipCity, ShipRegion, ShipPostalCode, ShipCountry, ChangesType, ChangedByUser, ChangesTime) 
				select *, 'deleted', SYSTEM_USER, SYSDATETIME() from deleted
		end
	else 
		begin
		if @change_type = 'inserted'
			begin 
				insert into dbo.OrdersHistory(OrderID, CustomerID, EmployeeID, OrderDate,
					RequiredDate, ShippedDate, ShipVia, Freight, ShipName, ShipAddress,
					ShipCity, ShipRegion, ShipPostalCode, ShipCountry, ChangesType, ChangedByUser, ChangesTime) 
					select *, 'inserted', SYSTEM_USER, SYSDATETIME() from inserted
			end
		else 
			begin
				insert into dbo.OrdersHistory(OrderID, CustomerID, EmployeeID, OrderDate,
					RequiredDate, ShippedDate, ShipVia, Freight, ShipName, ShipAddress,
					ShipCity, ShipRegion, ShipPostalCode, ShipCountry, ChangesType, ChangedByUser, ChangesTime) 
					select *, 'updates', SYSTEM_USER, SYSDATETIME() from inserted
			end
		end;
go;

insert into dbo.Orders (EmployeeID, ShipName, ShipRegion)
select 2, N'ShipShip', N'Russia';

select * from dbo.OrdersHistory;

delete from dbo.Orders 
where OrderID = 12112;

update dbo.Orders
set EmployeeID = 6 
where OrderID = 12113;