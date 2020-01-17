--10.1.	Две системы обмениваются между собой информацией с помощью 
--пересылки данных в виде XML. Необходимо реализовать обмен информации
--о заказах:
--1.Разработать формат XML сообщения для передачи/получения 
--информации о заказах (заголовок и табличная часть – таблицы Orders, 
--Order Details БД Northwind)
--Использовать будет формат auto поскольку он исключает дублирование 
--родительских элементов при наличии нескольких дочерних
--при передаче данных
use [Northwind];

select *
from dbo.Orders ord
inner join dbo.[Order Details] ordt on
	ord.OrderID = ordt.OrderID
for xml auto, elements;
--2.Разработать хранимую процедуру, которая будет формировать XML по конкретному заказу.
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'xml_for_order')
DROP PROCEDURE xml_for_order
GO
create proc xml_for_order @order_ID int as
select *
from dbo.Orders ord
inner join dbo.[Order Details] ordt on
	ord.OrderID = ordt.OrderID
where
	ord.OrderID = @order_ID for xml auto, elements;

--3.Разработать хранимую процедуру, которая будет получать XML с
--информацией о заказе и записывать данные в таблицы БД. При этом
--необходимо учитывать, что информация по заказу в таблицах уже может 
--быть, но отличатся количеством записей, значениями полей.
/*
Для выполнения задания необходимо в качестве источника использовать
таблицы Orders, Order Details БД Northwind, а в качестве получателя 
таблицы Orders, Order Details БД со структурой, аналогичной БД Northwind.
Необходимо использовать оператор merge.
*/

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'New_orders')
DROP PROCEDURE New_orders
GO
create proc New_orders @order_file xml as 

if (object_id('tempdb..#NewOrder') is not null) drop table #NewOrder;

create table #NewOrder( OrderID int primary key,
						CustomerID nchar(5) null,
						EmployeeID int null,
						OrderDate datetime null,
						RequiredDate datetime null,
						ShippedDate datetime null,
						ShipVia int null,
						Freight money null,
						ShipName nvarchar(60) null,
						ShipAddress nvarchar(60) null,
						ShipCity nvarchar(60) null,
						ShipRegion nvarchar(60) null,
						ShipPostalCode nvarchar(60) null,
						ShipCountry nvarchar(60) null )

DECLARE @handle INT
DECLARE @PrepareXmlStatus INT 
EXEC @PrepareXmlStatus = sp_xml_preparedocument @handle OUTPUT, @order_file

insert into	#NewOrder
SELECT *
FROM
	OPENXML(@handle, '/ord',2) 
WITH ( OrderID int,
	CustomerID nchar(5) ,
	EmployeeID int ,
	OrderDate datetime ,
	RequiredDate datetime ,
	ShippedDate datetime ,
	ShipVia int ,
	Freight money ,
	ShipName nvarchar(60) ,
	ShipAddress nvarchar(60) ,
	ShipCity nvarchar(60) ,
	ShipRegion nvarchar(60) ,
	ShipPostalCode nvarchar(60) ,
	ShipCountry nvarchar(60) ) 

merge into dbo.Orders as ord
using #NewOrder as new_ord on
	ord.OrderID = new_ord.OrderID
when Matched then
UPDATE
SET
	CustomerID = new_ord.CustomerID,
	EmployeeID = new_ord.EmployeeID,
	OrderDate = new_ord.OrderDate,
	RequiredDate = new_ord.RequiredDate,
	ShippedDate = new_ord.ShippedDate,
	ShipVia = new_ord.ShipVia,
	Freight = new_ord.Freight,
	ShipName = new_ord.ShipName,
	ShipAddress = new_ord.ShipAddress,
	ShipCity = new_ord.ShipCity,
	ShipRegion = new_ord.ShipRegion,
	ShipPostalCode = new_ord.ShipPostalCode,
	ShipCountry = new_ord.ShipCountry
when not matched then
insert
	(CustomerID,
	EmployeeID,
	OrderDate,
	RequiredDate,
	ShippedDate,
	ShipVia,
	Freight,
	ShipName,
	ShipAddress,
	ShipCity,
	ShipRegion,
	ShipPostalCode,
	ShipCountry)
values (CustomerID,
	EmployeeID,
	OrderDate,
	RequiredDate,
	ShippedDate,
	ShipVia,
	Freight,
	ShipName,
	ShipAddress,
	ShipCity,
	ShipRegion,
	ShipPostalCode,
	ShipCountry);

--10.2.	Дано:
/*
1) таблица с активами: Assets(AssetID, AssetName, Nominal, ClientPrice)
2) таблица с ценами активов на каждый день: Prices (AssetID, PriceDate, Price, ClientPrice).
Необходимо разработать хранимую процедуру, которая на вход принимает дату. 
В хранимой процедуцре должно обновлятся поле ClientPrice таблицы Assets
по данным из таблицы Prices. Если на указанную дату в тблице Prices поле 
ClientPrice = 0 или NULL, то нужно взять заполненное значение поля ClientPrice 
(ClientPrice > 0) на ближайшую дату, предшествующую указанной на входе процедуры.
Необходимо использовать outer apply или cross apply.
*/

Create table Assets(
	AssetID int primary key,
	AssetName varchar (50) not null, 
	Nominal varchar (50) null,
	ClientPrice int not null);

drop table Prices
Create table Prices (
	AssetID int not null,
	foreign key (AssetID) REFERENCES Assets (AssetID),
	PriceDate date null, 
	Price int not null,
	ClientPrice int not null);

insert into Assets 
values (123, 'asd', 'Rub', 100);

drop table Prices
insert into Prices
values (123, '2012-02-01', 200, 200),
	   (123, '2012-03-01', 300, 300),
	   (123, NULL, 0, 0),
	   (123, '2012-05-01', 400, 400);

--Создание процедуры
create or alter procedure UpdatePrice @Date date AS
update Assets
set ClientPrice = (select c.ClientPrice from Assets as a cross apply
	(select top(1)p.AssetID, p.ClientPrice,p.Price,p.PriceDate
	 from Prices p
	 where p.PriceDate<= @Date
	 order by p.PriceDate desc) as c);
--Проверка
exec UpdatePrice '2012-02-01'
select * from Assets