--
--»нициализаци€ таблиц
if (object_id('tempdb..#NameActive') is not null) drop table #NameActive;
create table #NameActive(
	CounterpartyID int primary key identity,
	Name varchar(255) not null,
	IsActive bit not null
)

insert into #NameActive (Name, IsActive)
values ('Ivanov', 1),
		('Petrov', 0),
		('Sidorov', 1);

if (object_id('tempdb..#transaction') is not null) drop table #transaction;
create table #transaction(
	TransID int	primary key identity,
	TransDate date not null,
	RcvID int not null,
	SndID int not null,
	AssetID int not null,
	Quantity numeric(19, 8) not null
)

insert into #transaction (TransDate, RcvID, SndID, AssetID, Quantity)
values ('2012-01-01', 1,	2,	1,	100),
		('2012-02-01',	1,	3,	2,	150),
		('2012-03-01',	3,	1,	1,	300),
		('2012-04-01',	2,	1,	3,	50);

select * from #NameActive;
select * from #transaction;

--6.1 уточним, что ситуаци€, когда пользователь переводит сам себе - исключена
--1)1)	ќтобрать активные счета по которым есть проводки как минимум по двум разным активам.
--¬ыводимые пол€: CounterpartyID, Name, Cnt(количество уникальных активов по которым есть проводки)
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

--2)2)	ѕосчитать суммарное число актива, образовавшеес€ на активных счетах, в результате 
--проведенных проводок. ¬ыводимые пол€: CounterpartyID, Name, AssetID, Quantity 
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

--3)3)	ѕосчитать средний дневной оборот по всем счетам по всем проводкам счита€ что
--AssetID во всех проводках одинаковый. ¬ыводимые пол€: CounterpartyID, Name, Oborot
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


--4)4)	ѕосчитать средний мес€чный оборот по всем счетам по всем проводкам счита€ что
--AssetID во всех проводках одинаковый. ¬ыводимые пол€: CounterpartyID, Name, Oborot
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

--6.2 ѕо таблице dbo.Employees дл€ каждого руководител€ найти подчиненных на всех уровн€х иерархии подчинени€ 
--(напр€му и через других подчиненных). ¬ывести руководител€, подчиненного, непосредственного руководител€ и уровень подчинени€. 
--ƒл€ построени€ иерархии в таблице используютс€ пол€ EmploeeID и ReportsTo.
--Ќеобходимо использовать рекурсивыный CTE.


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

