use Northwind;

/*
���������� ��������:
1. on ����� ������� �������� � �������� ��� �� ��� �� ������
��� � join
2. ��� join ��������� ������ ���������: inner join, outer left etc.
��� ����� �������� ������ � ����������������
3. �������� ������� �� ������
4. �������������� �� ����������. ����� ������ ������. ������ ������ �����
 */

--7.1 �������� ���������� ������� �� �������� ����������

/*
� ������ �� ������� ������� #categories?
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
������� with � ;, �����, ����, ���������� ������� ����������� ���
����� �����������, ����� ������, ������ ����� �� ����� �������� � ���,
��� ������ ���� ;
����� �� ������� ��� ��������� throw
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

--7.2 ������� ��������� ������� #Periods � ����� ������: PeriodID, Value. 
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

-- 7.2.1. ��������� �������� ������� � ������� �������� Value ���������� 
-- �� �������� Value � ���������� �������
with Prepared_Table
as
(select per.PeriodID,
		per.Value,
		lag(per.Value, 1, 0) over(order by PeriodID) as previous
from #Periods per) 
select pt.PeriodID, pt.Value
from Prepared_Table pt
where pt.Value != pt.previous;

--7.2.2. ��������� ������� �� ������� ������� � ������� �������� Value 
--����� �������� Value � ���������� �������. 

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

--7.3. ������ � ��������� �� Northwind, ��������� ������� �������, ������� ������������.

--7.3.1. ������������ ������ �� ������� Orders � ������� ���������� ������� 
--������ �� ��������.

select rank() over (order by datediff(day, ord.OrderDate, ord.ShippedDate) desc), * 
from dbo.Orders ord;

--7.3.2. �������� �� ��������� ���������, � ������� ���������� 
--����������� �� ����� ������ ������ ����.

/*
1. �� ����� ������
2. �������, dense_rank �� ������ �������� � ������ ��������
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

--7.3.3. �������� ������� 
--GetNums(@low bigint, @high bigint), 
--������� ���������� ������� � �������� n bigint.
--� ���� ������� ������ ���� ������������� �� ����������� �������� 
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
