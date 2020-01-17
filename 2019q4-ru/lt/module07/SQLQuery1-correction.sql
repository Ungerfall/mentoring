use Northwind;

--7.1 Получить статистику заказов по регионам покуателей
--Для каждой категории продукта (поле CategoryName  из таблицы Categories) 
--вывести средную стоимость заказов для покупателей из регионов AK, BC, CA, Co. Cork
--(поле Region  из таблицы Customers)
--Необходимо использовать оператор PIVOT
drop table if exists #categories;
select cat.CategoryName, cust.Region, ordd.UnitPrice*ordd.Quantity orderSum
into #categories
from dbo.Orders ord
inner join dbo.Customers cust
	on (ord.CustomerID = cust.CustomerID)
inner join dbo.[Order Details] ordd
	on (ord.OrderID = ordd.OrderID)
inner join dbo.Products prod
	on (ordd.ProductID = prod.ProductID)
inner join dbo.Categories cat
	on (prod.CategoryID = cat.CategoryID)
order by CategoryName;

;with Stat_Table as (
  select crt.CategoryName,
		crt.Region,
		crt.orderSum
from #categories crt
)
Select CategoryName, [AK], [BS], [CA], [Co. Cork]
from Stat_Table
pivot (avg(orderSum)
for Region in ([AK], [BS], [CA], [Co. Cork])) as P;

--7.2 Создать временную таблицу #Periods с двумя полями: PeriodID, Value. 
go
drop table if exists #Periods;
create table #Periods (
	PeriodID int,
	Value int 
);
insert into #Periods
values (1, 10),
	   (3, 10),
	   (5, 20),
	   (6, 20),
	   (7, 30),
	   (9, 40),
	   (10,	40);

-- 7.2.1. Требуется отобрать периоды в которых значение Value отличается 
-- от значения Value в предыдущем периоде Выводимые поля: PeriodID, Value. 
--В примере выше должны быть выведены значения 1, 5, 7, 9
with Prepared_Table
as
(select per.PeriodID,
		per.Value,
		lag(per.Value, 1, 0) over(order by PeriodID) as previous
from #Periods per) 
select pt.PeriodID, pt.Value
from Prepared_Table pt
where pt.Value != pt.previous;

--7.2.2. Требуется удалить из таблицы периоды в которых значение Value 
--равно значению Value в предыдущем периоде. Выводимые поля: PeriodID, Value. 
--В примере выше должны быть удалены значения 3, 6, 10.

with Prepared_Table
as
(select per.PeriodID,
		per.Value,
		lag(per.Value, 1, 0) over(order by PeriodID) as previous
from #Periods per) 
delete
from #Periods
where PeriodID in (select pt.PeriodID
from Prepared_Table pt
where pt.Value != pt.previous);

--7.3. Работа с таблицами БД Northwind, используя оконные функции, функции ранжирования.

--7.3.1. Пронумеруйте заказы из таблицы Orders в порядке уменьшения времени 
--затрат на доставку.

select rank() over (order by datediff(day, ord.OrderDate, ord.ShippedDate) desc), * 
from dbo.Orders ord;

--7.3.2. Выберите те категории продуктов, у которых количество 
--поставщиков из одной страны больше трех.

/*
2. Подумай, dense_rank не совсем подходит в случае коллизий

 */
 --не совсем понимаю почему? Правильно ли я понимаю, что нужно значит использовать rank()?
with Rank_Supp_Table
as
(select distinct prod.CategoryID,
		prod.SupplierID,
		Rank() over (partition by prod.SupplierID, prod.CategoryID order by prod.SupplierID) supp_Rank
from dbo.Products prod
)
select rst.CategoryID
from Rank_Supp_Table rst
where rst.supp_Rank = 4;

--7.3.3. Создайте функцию 
--GetNums(@low bigint, @high bigint), 
--которая возвращает таблицу с колонкой n bigint.
--В этой таблице должны быть упорядоченные по возрастанию значения 
--от @low до @high (количеством записей @high - @low + 1).
--Например GetNums(5, 9)должна вернуть таблицу:

go
create or alter function GetNums(@low as bigint,
						@high as bigint) 
returns table
as
return 
with
    zero_table   as (select zeros from (values(0),(0)) as tabl(zeros)),
    zero_table_1 as (select 0 as zeros from zero_table as tabl1 cross join zero_table as tabl2),
    zero_table_2 as (select 0 as zeros from zero_table_1 as tabl1 cross join zero_table_1 as tabl2),
	zero_table_3 as (select 0 as zeros from zero_table_2 as tabl1 cross join zero_table_2 as tabl2),
	zero_table_4 as (select 0 as zeros from zero_table_3 as tabl1 cross join zero_table_3 as tabl2),
    Number_table as (select row_number() over(order by (select null)) as numbers from zero_table_4)
  select top(@high - @low + 1) @low + numbers - 1 as n
  from Number_table
  order by numbers;

  select * from GetNums(5, 9);
