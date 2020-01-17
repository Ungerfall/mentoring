use Northwind;

/*
Внутреннее качество:
1. on более читаемо выглядит с отступом или на той же строке
где и join
2. для join используй полный синтаксис: inner join, outer left etc.
Так проще избежать ошибок и неоднозначностей
3. описание заданий не полное
4. Форматирование не одинаковое. Очень тяжело читать. Следуй одному стилю
 */

--7.1 Получить статистику заказов по регионам покуателей

/*
А почему не назвать таблицу #categories?
 */
drop table if exists #CatRegTable;
select cat.CategoryName, cust.Region, ordd.UnitPrice*ordd.Quantity orderSum
into #CatRegTable
from dbo.Orders ord
join dbo.Customers cust
on (ord.CustomerID = cust.CustomerID)
join dbo.[Order Details] ordd
on (ord.OrderID = ordd.OrderID)
join dbo.Products prod
on (ordd.ProductID = prod.ProductID)
join dbo.Categories cat
on (prod.CategoryID = cat.CategoryID)
order by CategoryName;

/*
начинай with с ;, иначе, если, предыдущая команда завершилась без
этого терминатора, будет ошибка, причем текст не будет говорить о том,
что упущен знак ;
такое же правило для оператора throw
 */
with Stat_Table as (
  select crt.CategoryName,
		crt.Region,
		crt.orderSum
from #CatRegTable crt
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
-- от значения Value в предыдущем периоде
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
--равно значению Value в предыдущем периоде. 

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
1. Из одной страны
2. Подумай, dense_rank не совсем подходит в случае коллизий
 */
with Rank_Supp_Table
as
(select distinct prod.CategoryID,
		prod.SupplierID,
		Dense_rank() over (partition by prod.CategoryID order by prod.SupplierID) supp_Rank
from dbo.Products prod
)
select rst.CategoryID
from Rank_Supp_Table rst
where rst.supp_Rank = 4;

--7.3.3. Создайте функцию 
--GetNums(@low bigint, @high bigint), 
--которая возвращает таблицу с колонкой n bigint.
--В этой таблице должны быть упорядоченные по возрастанию значения 
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
