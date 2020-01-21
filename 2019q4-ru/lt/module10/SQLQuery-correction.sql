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

/*
1. Лучше отказаться от wildcard символа в пользу поддерживаемости.
Разработчикам будет хорошо видно, что именно возвращается и не
нужно смотреть структуру таблиц. +
Плюс, любое изменение таблиц приведет к плохим последствиям на стороне клиента
2. Обрати внимание, как формируется поле Discount. Нужно формат сделать строже +
*/
select ord.OrderID,
	   ord.CustomerID,
	   ord.EmployeeID,
	   ord.Freight,
	   ord.OrderDate,
	   ord.RequiredDate,
	   ord.ShipAddress,
	   ord.ShipCity,
	   ord.ShipCountry,
	   ord.ShipName,
	   ord.ShippedDate,
	   ord.ShipPostalCode,
	   ord.ShipRegion,
	   ord.ShipVia,
	   ordt.Discount,
	   ordt.OrderID,
	   ordt.ProductID,
	   ordt.Quantity,
	   ordt.UnitPrice
from dbo.Orders ord
inner join dbo.[Order Details] ordt on
	ord.OrderID = ordt.OrderID
	where ordt.Discount != 0
for xml auto, elements, type;
--2.Разработать хранимую процедуру, которая будет формировать XML по конкретному заказу.
/*
1. Отсутствие схемы +
2. Wildcard (смотри описание выше) +
3. Строгий формат +
*/
create or alter proc xml_for_order @order_ID int as
select ord.CustomerID,
	   ord.EmployeeID,
	   ord.Freight,
	   ord.OrderDate,
	   ord.RequiredDate,
	   ord.ShipAddress,
	   ord.ShipCity,
	   ord.ShipCountry,
	   ord.ShipName,
	   ord.ShippedDate,
	   ord.ShipPostalCode,
	   ord.ShipRegion,
	   ord.ShipVia,
	   ordt.Discount,
	   ordt.OrderID,
	   ordt.ProductID,
	   ordt.Quantity,
	   ordt.UnitPrice
from dbo.Orders ord
inner join dbo.[Order Details] ordt on
	ord.OrderID = ordt.OrderID
where
	ord.OrderID = @order_ID 
for xml auto, xmldata, type, elements;

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

/*
	1. Переделать на not exists (заменил на create or alter)
	2. Использовать OPENXML необходимо только в тех случаях,
когда нужно разбивать input xml несколько раз, но в нашем случае
достаточно только 1 раз, поэтому у нас выходит издержки на создание
DOM объекта. +
*/
--IF NOT EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'New_orders')
--DROP PROCEDURE New_orders
--GO
create or alter proc New_orders @order_file xml as 

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

insert into	#NewOrder
SELECT Columns.value('(OrderID)[1]', 'int') AS 'OrderID',
	   Columns.value('(CustomerID)[1]', 'nchar(5)') AS 'CustomerID',
	   Columns.value('(EmployeeID)[1]', 'int') AS 'EmployeeID',
	   Columns.value('(OrderDate)[1]', 'datetime') AS 'Freight',
	   Columns.value('(RequiredDate)[1]', 'datetime') AS 'RequiredDate',
	   Columns.value('(ShippedDate)[1]', 'datetime') AS 'ShippedDate',
	   Columns.value('(ShipVia)[1]', 'int') AS 'ShipVia',
	   Columns.value('(Freight)[1]', 'Varchar(50)') AS 'Freight',
	   Columns.value('(ShipName)[1]', 'nvarchar(60)') AS 'ShipName',
	   Columns.value('(ShipAddress)[1]', 'nvarchar(60)') AS 'ShipAddress',
	   Columns.value('(ShipCity)[1]', 'nvarchar(60)') AS 'ShipCity',
	   Columns.value('(ShipRegion)[1]', 'nvarchar(60)') AS 'ShipRegion',
	   Columns.value('(ShipPostalCode)[1]', 'nvarchar(60)') AS 'ShipPostalCode',
	   Columns.value('(ShipCountry)[1]', 'nvarchar(60)') AS 'ShipCountry'
	   
	   --Columns.value('(ordt/Discount)[1]', 'real') AS 'Discount',
	   --Columns.value('(ordt/OrderID)[1]', 'int') AS 'OrderID',
	   --Columns.value('(ordt/ProductID)[1]', 'int') AS 'ProductID',
	   --Columns.value('(ordt/UnitPrice)[1]', 'money') AS 'UnitPrice'
FROM
	@order_file.nodes('/ord') as ord(Columns)
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

/*
1. Форматирование. Невозможно читать
*/
drop table if exists dbo.Prices;
drop table if exists dbo.Assets;
Create table Assets(
	AssetID int primary key,
	AssetName varchar (50) not null, 
	Nominal varchar (50) null,
	ClientPrice int not null);
Create table Prices (
	AssetID int not null,
	foreign key (AssetID) REFERENCES Assets (AssetID),
	PriceDate date null, 
	Price int not null,
	ClientPrice int not null);

insert into Assets 
	values (123, 'asd', 'Rub', 100);

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