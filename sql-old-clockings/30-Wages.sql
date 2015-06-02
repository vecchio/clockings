/*  */
select now() as "Wages Hours Start";

create temp table reportdatesraw (
StartDate    varchar(64),
EndDate      varchar(64) );

-- select * from reportdatesraw ;
-- delete from reportdatesraw ;

copy reportdatesraw from E'c:\\clockings\\30-Wages-Input.csv' with csv header;
-- copy reportdatesraw from  '/home/gdt/RosesClockings/30-Wages-Input.csv' with csv header;

create temp table reportdates as
select to_date(
       substring(startdate from 1  for 4) || ' ' ||
       substring(startdate from 6  for 2) || ' ' ||
       substring(startdate from 9  for 2)
       , 'YYYY MM DD') as startdate,
       to_date(
       substring(enddate from 1  for 4) || ' ' ||
       substring(enddate from 6  for 2) || ' ' ||
       substring(enddate from 9  for 2)
       , 'YYYY MM DD') as enddate
from reportdatesraw;

create temp table clockinout as
select i.emp, i.fname, i.lname, i.wday, i.dir as idir, i.clock as iclock, o.dir as odir, o.clock as oclock
  from clockmaster i, clockmaster o, reportdates d
 where i.emp = o.emp
   and i.wday >= d.startdate
   and i.wday <= d.enddate
   and i.wday = o.wday
   and i.dir = 'in'
   and o.dir = 'out'
  order by emp, iclock, oclock;

delete from clockinout where oclock <  iclock;



-- remove multiple clock outs
create temp table clockinoutclean_o as
select emp, fname, lname, wday, idir, iclock, odir, min(oclock) as oclock
  from clockinout
  group by emp, fname, lname, wday, idir, iclock, odir
  order by emp, iclock, oclock;

-- remove multiple clock ins
create temp table clockinoutclean as
select emp, fname, lname, wday, idir, 
min(iclock) as iclock, 
odir, oclock
  from clockinoutclean_o
  group by emp, fname, lname, wday, idir, oclock, odir
  order by emp, iclock, oclock;

create temp table clockinoutduration as
 select *, (oclock - iclock) as dur
   from clockinoutclean
  order by emp, iclock;


create temp table clockempday as
 select emp, fname, lname, wday, sum(dur) as dur, count(1) as entries, 0::numeric(8,2) as pay,
        case when extract(hour from min(iclock)) >= 16 and extract(min from min(Iclock)) >= 15
           then 1 
           else 0 
        end as n
   from clockinoutduration 
  group by emp, fname, lname, wday
  order by emp, wday;  

select count(1) from clockempday;
-- alter table clockempday add column emp int;
-- select * from clockempday order by wday, emp;  

update clockempday set pay = (((extract(hours from dur) * 60) + (extract(minutes from dur) + 50))/60)::numeric(8,2);
update clockempday set pay = trunc(pay) where (pay-trunc(pay)) between 0.0 and 0.11;
update clockempday set pay = (trunc(pay)+ 0.25) where (pay-trunc(pay)) between 0.12 and 0.25;
update clockempday set pay = (trunc(pay)+ 0.25) where (pay-trunc(pay)) between 0.26 and 0.36;
update clockempday set pay = (trunc(pay)+ 0.5) where (pay-trunc(pay)) between 0.37 and 0.5;
update clockempday set pay = (trunc(pay)+ 0.5) where (pay-trunc(pay)) between 0.51 and 0.61;
update clockempday set pay = (trunc(pay)+ 0.75) where (pay-trunc(pay)) between 0.62 and 0.75;
update clockempday set pay = (trunc(pay)+ 0.75) where (pay-trunc(pay)) between 0.76 and 0.86;
update clockempday set pay = (trunc(pay)+ 1.00) where (pay-trunc(pay)) > 0.86;

create temp table clockempweek as
 select emp, fname, lname, sum(dur) as dur, sum(pay) as pay
   from clockempday 
  group by emp, fname, lname
  order by emp;  

copy (select m.* from clockmaster m, reportdates r where m.wday >= r.startdate and m.wday <= r.enddate order by emp, clock)
  to E'c:\\clockings\\30-Wages-Clock-Report.csv' with csv header;
  -- to '/home/gdt/RosesClockings/30-Wages-Clock-Report.csv' with csv header;

copy clockinoutduration to E'c:\\clockings\\30-Wages-Duration-Report.csv' with csv header;
copy clockempday        to E'c:\\clockings\\30-Wages-Day-Report.csv' with csv header;
copy clockempweek       to E'c:\\clockings\\30-Wages-Week-Report.csv' with csv header;

-- copy clockinoutduration to '/home/gdt/RosesClockings/30-Wages-Duration-Report.csv' with csv header;
-- copy clockempday        to '/home/gdt/RosesClockings/30-Wages-Day-Report.csv' with csv header;
-- copy clockempweek       to '/home/gdt/RosesClockings/30-Wages-Week-Report.csv' with csv header;

create temp table pubraw (
PubDate   varchar(64),
PubDay     varchar(64) );

copy pubraw from E'c:\\clockings\\80-Public-Holidays-Input.csv' with csv header;
-- copy pubraw from '/home/gdt/RosesClockings/80-Public-Holidays-Input.csv' with csv header;

create temp table pub as
select to_date(
       substring(PubDate from 1  for 4) || ' ' ||
       substring(PubDate from 6  for 2) || ' ' ||
       substring(PubDate from 9  for 2)
       , 'YYYY MM DD') as pubdate,
       pubday
from pubraw; 

create temp table emas (
seqc    varchar(64),
empc    varchar(64),
fname   varchar(64),
lname   varchar(64)  );

copy emas from E'c:\\clockings\\EmpMaster.csv' with csv header;
-- copy rcall from '/home/gdt/RosesClockings/EmpMaster.csv' with csv header;
-- select * from emas;

alter table emas add column emp int;
alter table emas add column seq int;
update emas set emp = trim(leading 'P' from empc)::int;     
update emas set seq = seqc::int;     

create temp table byweekday_big as
select wday, emp, n, 

			sum(case
			    when extract(dow from wday) = 0  and pubdate is null
			    then pay
			    else 0
			end) as sun,
			sum(case
			    when extract(dow from wday) = 1 and pubdate is null
			    then pay
			    else 0
			end) as mon,
			sum(case
			    when extract(dow from wday) = 2  and pubdate is null
			    then pay
			    else 0
			end) as tue    ,			
			sum(case
			    when extract(dow from wday) = 3  and pubdate is null
			    then pay
			    else 0
			end) as wed   , 
			sum(case
			    when extract(dow from wday) = 4  and pubdate is null
			    then pay
			    else 0
			end) as thu,
			sum(case
			    when extract(dow from wday) = 5  and pubdate is null
			    then pay
			    else 0
			end) as fri,
			sum(case
			    when extract(dow from wday) = 6  and pubdate is null
			    then pay
			    else 0
			end) as sat,
			sum(case
			    when pubdate is not null
			    then pay
			    else 0
			end) as pub

from clockempday left join pub on wday = pubdate
group by wday, emp, n
order by emp, wday;

create temp table byweekday as
select emas.empc as emp, emas.fname, emas.lname, case when sum(n) > 0 then 'N' else '' end as n,
	             sum(wed) as wed,
	             sum(thu) as thu,
	             sum(fri) as fri,
	             sum(sat) as sat,
	             sum(sun) as sun,
		     sum(mon) as mon, 
	             sum(tue) as tue,	             
	             sum(pub) as pub,
		     sum(mon)+sum(tue)+sum(wed)+sum(thu)+sum(fri)+sum(sat)+sum(sun)+sum(pub) as tot

from emas left join byweekday_big on emas.emp = byweekday_big.emp
group by emas.seq, emas.empc, emas.fname, emas.lname
order by emas.seq;

copy byweekday       to E'c:\\clockings\\30-Wages-By-Day-of-Week-Report.csv' with csv header;
  
select now() as "Payroll Hours Done";
