/*3.1.1. Найти общую сумму всех заказов из таблицы Order Details с учетом количества закупленных товаров и скидок по ним.
Результат округлить до сотых и высветить в стиле 1 для типа данных money.
Скидка (колонка Discount) составляет процент из стоимости для данного товара.
Для определения действительной цены на проданный продукт надо вычесть скидку из указанной в колонке UnitPrice цены.
Результатом запроса должна быть одна запись с одной колонкой с названием колонки 'Totals'.*/

SELECT CONVERT(money, round(Sum((details.UnitPrice - details.UnitPrice * details.Discount) * details.Quantity), 2), 1)  as Totals
FROM dbo.[Order Details] details;
GO

********************************************************************************
Всё верно.
Небольшое замечание: функции писать в одном стиле. CONVERT, но Sum
********************************************************************************

/*3.1.2. По таблице Orders найти количество заказов, которые еще не были доставлены (т.е. в колонке ShippedDate нет значения даты доставки).
Использовать при этом запросе только оператор COUNT.
Не использовать предложения WHERE и GROUP.*/

SELECT Count(ord.ShippedDate) as ShippedCount
FROM dbo.Orders ord;
GO

********************************************************************************
Ошибка. Твой запрос возвращает количество доставленных заказов.
********************************************************************************

/*3.1.3. По таблице Orders найти количество различных покупателей (CustomerID), сделавших заказы.
Использовать функцию COUNT и не использовать предложения WHERE и GROUP.*/

SELECT Count(DISTINCT ord.CustomerID) as UniqueCustomerCount
FROM dbo.Orders ord;
GO

********************************************************************************
Верно.
********************************************************************************

/*3.2.1. По таблице Orders найти количество заказов с группировкой по годам.
В результатах запроса надо высвечивать две колонки c названиями Year и Total.*/

SELECT YEAR(ord.OrderDate) as Year, Count(ord.OrderDate) as Total
FROM dbo.Orders ord
GROUP BY YEAR(ord.OrderDate);
GO

/*Написать проверочный запрос, который вычисляет количество всех заказов.*/

SELECT Count(ord.OrderDate) as Total
FROM dbo.Orders ord;
GO

********************************************************************************
Верно. COUNT лучше писать в нашем случае COUNT(*), не нужно в таком случае 
учитывать NULL ограничение колонки.
********************************************************************************

/*3.2.2. По таблице Orders найти количество заказов, оформленных каждым продавцом.
Заказ для указанного продавца – это любая запись в таблице Orders, где в колонке EmployeeID задано значение для данного продавца.
В результатах запроса надо высвечивать колонку с именем продавца (Должно высвечиваться имя полученное конкатенацией LastName & FirstName. 
Эта строка LastName & FirstName должна быть получена отдельным запросом в колонке основного запроса. 
Также основной запрос должен использовать группировку по EmployeeID.) с названием колонки ‘Seller’ и колонку c количеством заказов высвечивать с названием 'Amount'.
Результаты запроса должны быть упорядочены по убыванию количества заказов.*/

SELECT CONCAT(emp.LastName, N' ', emp.FirstName) as Seller, ord.Amount as Amount
FROM
	(SELECT ord.EmployeeID, Count(ord.EmployeeID) as Amount
	FROM dbo.Orders ord
	GROUP BY ord.EmployeeID) as ord
JOIN dbo.Employees as emp on emp.EmployeeID = ord.EmployeeID
ORDER BY Amount DESC;

GO

********************************************************************************
Верно. Как и обсудили ранее, колонку Seller можно формировать подзапросом по 
EmloyeeId из FROM
********************************************************************************

/*3.2.3 По таблице Orders найти количество заказов
Условия:
• Заказы сделаны каждым продавцом и для каждого покупателя;
• Заказы сделаны в 1998 году.
В результатах запроса надо высвечивать:
• Колонку с именем продавца (название колонки ‘Seller’);
• Колонку с именем покупателя (название колонки ‘Customer’);
• Колонку c количеством заказов высвечивать с названием 'Amount'.
В запросе необходимо использовать специальный оператор языка T-SQL для работы с выражением GROUP (Этот же оператор поможет выводить строку “ALL” в результатах запроса).
Группировки должны быть сделаны по ID продавца и покупателя.
Результаты запроса должны быть упорядочены по:
• Продавцу;
• Покупателю;
• убыванию количества продаж.
В результатах должна быть сводная информация по продажам.: 
Seller Customer Amount 
ALL ALL <общее число продаж> 
<имя> ALL <число продаж для данного продавца> 
ALL <имя> <число продаж для данного покупателя> 
<имя> <имя> <число продаж данного продавца для даннного покупателя>*/

SELECT (CASE
		 WHEN GROUPING(ord.EmployeeID) = 1 THEN N'ALL'
		 ELSE CONCAT(MIN(emp.LastName), N' ', MIN(emp.FirstName))
		END) AS Seller
		,
		(CASE
		 WHEN GROUPING(ord.CustomerID) = 1 THEN N'ALL'
		 ELSE MIN(cus.ContactName)
		END) AS Customer
		, 
		Count(*) AS Amount
FROM dbo.Orders ord
JOIN dbo.Employees emp ON emp.EmployeeID = ord.EmployeeID
JOIN dbo.Customers cus ON cus.CustomerID = ord.CustomerID
WHERE YEAR(ord.OrderDate) = 1998
GROUP BY CUBE(ord.EmployeeID, ord.CustomerID)
ORDER BY ord.EmployeeID, ord.CustomerID, Amount DESC
;
GO

********************************************************************************
Исправить для лучшей читаемости формирование Sellec с помощью подзапроса.
Таблица не большая, поэтому дополнительной нагрузки не будет
********************************************************************************

/*3.2.4. Найти покупателей и продавцов, которые живут в одном городе.
Если в городе живут только продавцы или только покупатели, то информация о таких покупателя и продавцах не должна попадать в результирующий набор.
В результатах запроса необходимо вывести следующие заголовки для результатов запроса:
• ‘Person’;
• ‘Type’ (здесь надо выводить строку ‘Customer’ или ‘Seller’ в завимости от типа записи);
• ‘City’.
Отсортировать результаты запроса по колонке ‘City’ и по ‘Person’.*/

SELECT Person, Type, City
FROM
	(SELECT CONCAT(emp.LastName, N' ', emp.FirstName) AS Person , N'Seller' AS Type, emp.City AS City
	FROM dbo.Employees emp
	WHERE emp.City IN (SELECT customerCities.City FROM dbo.Customers customerCities)
	GROUP BY emp.EmployeeID, emp.LastName, emp.FirstName, emp.City	
	) as res
UNION
SELECT Person, Type, City
FROM
	(SELECT cus.ContactName AS Person , N'Customer' AS Type, cus.City AS City
	FROM dbo.Customers cus
	WHERE cus.City IN (SELECT sellerCities.City FROM dbo.Employees sellerCities)
	GROUP BY cus.CustomerID, cus.ContactName, cus.City	
	) as res
ORDER BY res.City, res.Person
;
GO

********************************************************************************
Alias customerCities избыточен. Ты алиасишь таблицу, но не колонку
Группировка не нужна. Группируя по EmployeeID, ты уже выбираешь все данные
********************************************************************************

/*3.2.5. Найти всех покупателей, которые живут в одном городе.
В запросе использовать соединение таблицы Customers c собой - самосоединение. Высветить колонки CustomerID и City.
Запрос не должен высвечивать дублируемые записи.
*/

SELECT DISTINCT cus1.CustomerID, cus1.City
FROM dbo.Customers cus1, dbo.Customers cus2
WHERE cus1.CustomerID <> cus2.CustomerID AND cus1.City = cus2.city
;
GO

/*Для проверки написать запрос, который высвечивает города, которые встречаются более одного раза в таблице Customers. Это позволит проверить правильность запроса.*/

SELECT MIN(cus.City) AS City, COUNT(cus.City) AS Count
FROM dbo.Customers cus
GROUP BY cus.City
HAVING COUNT(cus.City) > 1
ORDER BY Count DESC
;
GO

********************************************************************************
Для self JOIN лучше использовать новый синтаксис с использованием JOIN для 
лучшей читаемости
********************************************************************************

/*3.2.6. По таблице Employees найти для каждого продавца его руководителя, т.е. кому он делает репорты.
Высветить колонки с именами 'User Name' (LastName) и 'Boss'. В колонках должны быть высвечены имена из колонки LastName.*/

SELECT emp.LastName AS N'User Name', boosEmp.LastName AS Boss
FROM dbo.Employees emp
LEFT JOIN dbo.Employees boosEmp ON emp.ReportsTo = boosEmp.EmployeeID
--INNER JOIN dbo.Employees boosEmp ON emp.ReportsTo = boosEmp.EmployeeID
;
GO

/*Высвечены ли все продавцы в этом запросе?*/

--Зависит от того, какой тип Join-а использовать, LEFT JOIN выведет всех продавцов, для тех, у кого нет босса - будет NULL, (INNER JOIN) покажет только тех, у кого есть босс

********************************************************************************
Верно
********************************************************************************

