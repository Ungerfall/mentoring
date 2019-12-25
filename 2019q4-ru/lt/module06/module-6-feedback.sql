/*
¬нутреннее качество:
1. отсутствуют описани€ задач
2. ‘орматирование (колонки таблиц с новой строки, null/not null)
 */

--»нициализаци€ таблиц
/*
скрипт невозможно будет прогнать несколько раз,
потому что ошибка "таблица существует"
используй такой паттерн:
if (object_id('tempdb..#NameActive') is not null) drop table #NameActive;
название таблицы не самое удачное
 */
create table #NameActive
(CounterpartyID int primary key identity,
Name varchar(255),
IsActive bit
)

insert into #NameActive
values ('Ivanov', 1),
		('Petrov', 0),
		('Sidorov', 1)	;

create table #transaction
(
TransID int	primary key identity,
TransDate date,
RcvID int,
SndID int,
AssetID int,
Quantity numeric(19, 8)
)

/*
1. ansi формат дл€ дат
2. колонки таблицы в которые данные вставл€ютс€
 */
insert into #transaction
values ('01.01.2012', 1,	2,	1,	100),
('02.01.2012',	1,	3,	2,	150),
('03.01.2012',	3,	1,	1,	300),
('04.01.2012',	2,	1,	3,	50);

select * from #NameActive;
select * from #transaction;

--6.1 уточним, что ситуаци€, когда пользователь переводит сам себе - исключена
--1)
with all_trans 
as(
	select RcvID as unit, AssetID from #transaction
	union all
	select SndID as unit, AssetID from #transaction
)
select na.CounterpartyID, 
	   na.Name, 
	   count(distinct all_trans.AssetID)
from all_trans
join #NameActive na
on all_trans.unit = na.CounterpartyID
and na.IsActive = 1
group by na.CounterpartyID, na.Name;

--2)
with all_trans 
as(
	select RcvID as unit, AssetID, -Quantity qa from #transaction
	union all
	select SndID as unit, AssetID, Quantity qa from #transaction
)
select na.CounterpartyID, 
	   na.Name, 
	   AssetID,
	   SUM(qa)
from all_trans
join #NameActive na
on all_trans.unit = na.CounterpartyID
and na.IsActive = 1
group by na.CounterpartyID, na.Name, all_trans.AssetID
order by na.CounterpartyID;

--3)
with all_trans 
as(
	select RcvID as unit, TransDate trans_date, -Quantity qa from #transaction
	union all
	select SndID as unit, TransDate trans_date, Quantity qa from #transaction
)
select na.CounterpartyID, 
	   na.Name, 
	   sum(qa)/(SELECT count(distinct day(TransDate)) FROM #transaction) Oborot
from all_trans
join #NameActive na
on all_trans.unit = na.CounterpartyID
group by na.CounterpartyID, na.Name
order by na.CounterpartyID;


--4)
with all_trans 
as(
	select RcvID as unit, TransDate trans_date, -Quantity qa from #transaction
	union all
	select SndID as unit, TransDate trans_date, Quantity qa from #transaction
)
select na.CounterpartyID, 
	   na.Name, 
	   sum(qa)/(SELECT count(distinct month(TransDate)) FROM #transaction) Oborot
from all_trans
join #NameActive na
on all_trans.unit = na.CounterpartyID
group by na.CounterpartyID, na.Name
order by na.CounterpartyID;

--6.2

declare @boss as nvarchar = (select emp.EmployeeID from dbo.Employees emp where emp.ReportsTo is null);
declare @bossName as nvarchar(10) = (select emp.LastName from dbo.Employees emp where emp.EmployeeID = @boss);
;with RecCTE
as 
(
	select @bossName as boss, e.EmployeeID, e.LastName as subordinate, e.ReportsTo,B.LastName as RealChief,   0 as [lvl]
	from dbo.Employees as E
	join dbo.Employees as B
	on (e.ReportsTo = B.EmployeeID)
	where E.ReportsTo = @boss
	union all
	select @bossName as boss, M.EmployeeID, M.LastName as subordinate, M.ReportsTo,B.LastName as RealChief,   S.[lvl] + 1 as [lvl]
	from RecCTE as S
	inner join 
	dbo.Employees as M 
	on (S.EmployeeID= M.ReportsTo )
	inner join 
	dbo.Employees as B
	on (M.ReportsTo = B.EmployeeID)
)
select boss, subordinate, RealChief, [lvl] from RecCTE

