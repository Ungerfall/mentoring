use Northwind;
--9.1.	Написать скрипт создания индекса для таблицы dbo.Employees для поля PostalCode 
--(имя индекса должно быть PostalCode). Сделать обязательную проверку при создании 
--индекса на существование данного индекса в таблице.
/*
На будущее: лучше имена индексам давать с определенным префиксом согласно принятой конвенции именования.
Таким образом удастся обеспечить уникальности объектов базы.
Но, посколько это требование, то всё хорошо и ошибки нет.
Второе, лучше перевернуть проверку и проверять отсутствие индекса с последующим
созданием. drop/create индекса приведет к созданию индекса, что может занять большое
кол-во времени
*/
IF EXISTS (SELECT * FROM sys.indexes WHERE NAME = 'PostalCode' AND object_id = object_id('dbo.Employees'))
DROP INDEX PostalCode on dbo.Employees;
CREATE NONCLUSTERED INDEX PostalCode
ON dbo.Employees (PostalCode ASC);

--9.2.	Написать скрипт, который обновит в поле PostalCode таблицы dbo.Employees все не 
--числоввые символы на любые числовые.
UPDATE dbo.Employees
SET PostalCode = CASE
WHEN PostalCode LIKE '%[A-Z]%'
THEN 142343
ELSE PostalCode
END;

--9.3.	Построить план и оптимизировать запрос, представленный ниже, так чтобы индекс 
--индекс PostalCode работал не по табличному сканированию (Index Scan), а по Index Seek.
--Необходимо пояснить, почему вы оптимизировали запрос именно так?

SELECT  EmployeeID
FROM    dbo.Employees
WHERE   LEFT(PostalCode, 2) = '98';
--как мы знаем, функции являются NON-SARG. Исходя из этого можно сделать вывод, что 
--для того, чтобы PostalCode работал не по табличному сканированию (Index Scan), а по Index Seek
--необходимо изменить способ сортировки данных. 
--like '98%' - выполняет аналогичную сортировку данных, но является SARG.
SELECT  EmployeeID
FROM    dbo.Employees
WHERE   PostalCode like '98%';

--9.4.	Разобраться с планом запроса, представленного ниже скрипта. Оптимизировать запрос.
--Пояснить подробно почему вы считаете, что ваш вариант оптимизации наиболее оптимизирует 
-- данный запрос и увеличит его быстродействие?

/*
Можно и даже лучше использовать функцию GetNums, которую ты разработал в одном из
предыдущих модулей. Меньше кода и без циклов
*/

--Для проверки быстродействия необходимо вставить в задействованные таблицы 1000000+ записей. 
--dbo.Customers
DECLARE @alphabet VARCHAR(36) = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
DECLARE @i int;
SET @i = 0;
WHILE @i < 1000000
BEGIN
INSERT INTO dbo.Customers(CustomerID, CompanyName)
VALUES (substring(@alphabet, convert(int, rand()*36), 1) +
				substring(@alphabet, convert(int, rand()*36), 1) +
				substring(@alphabet, convert(int, rand()*36), 1) +
				substring(@alphabet, convert(int, rand()*36), 1) +
				substring(@alphabet, convert(int, rand()*36), 1), str(@i+11));
SET @i = @i + 1;
END;

--dbo.Employees
DECLARE @i int;
SET @i = 0;
WHILE @i < 1000
BEGIN
INSERT INTO dbo.Employees(FirstName, LastName)
VALUES ('', '');
SET @i = @i + 1;
END;

--dbo.Orders
DECLARE @i int;
SET @i = 0;
WHILE @i < 1000000
BEGIN
INSERT INTO dbo.Orders (CustomerID, EmployeeID, ShippedDate)
VALUES ('AVDRW', 637, N'1996-02-01 00:00:00')
SET @i = @i + 1;
END;

--dbo.Products
DECLARE @i int;
SET @i = 0
WHILE @i < 1000000
BEGIN
INSERT INTO dbo.Products(ProductName)
VALUES ('Product')
SET @i = @i + 1;
END;
select * from dbo.Products

--[Order Details]
DECLARE @i int;
SET @i = 0
WHILE @i < 1000000
BEGIN
INSERT INTO dbo.[Order Details](OrderID, ProductID, UnitPrice)
VALUES (10258 + @i, @i, 100)
SET @i = @i + 1
END
--
DECLARE @OrderDate DATETIME = N'1996-01-01 00:00:00'

SELECT  OrderId = ordr.OrderID,
                 EmployeeName = ISNULL(empl.FirstName, '') + ' ' + ISNULL(empl.LastName, ''),
                 CustomerId = ordr.CustomerID,
	             CompanyName = cust.CompanyName,
                 ShippedDate = ordr.ShippedDate,
                 ProductName = prod.ProductName
FROM    dbo.Orders ordr
INNER JOIN dbo.[Order Details] ord ON ord.OrderID = ordr.OrderID
INNER JOIN dbo.Products prod ON ord.ProductID = prod.ProductID
INNER JOIN dbo.Customers cust ON ordr.CustomerID = cust.CustomerID
INNER JOIN dbo.Employees empl ON ordr.EmployeeID = empl.EmployeeID
WHERE ordr.OrderDate >= @OrderDate;
--После того как данных становится достаточно много оптимизатор использует
--Index Seek. Все необходимые для данного запроса Индексы созданы
--В момент времени, когда необходимо объеденить таблицы - используется hash Match
--На мой взгляд он является оптимальным в этой задаче, поскольку 
--merge join будет затрачивать большое количество ресурсов, 
--а Nested loops будет отрабатывать очень долго. 
--Возможно удобно будет создать план запроса уже в базе и в дальнейшем 
--использовать его из Кэша.