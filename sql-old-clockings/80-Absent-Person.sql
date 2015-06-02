select now() as "Absent Person Begin";

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

create temp table apraw (
Emp	    varchar(64),
StartDate   varchar(64),
EndDate     varchar(64)  );

copy apraw from E'c:\\clockings\\80-Absent-Person-Input.csv' with csv header;
-- copy apraw from '/home/gdt/RosesClockings/80-Absent-Person-Input.csv' with csv header;

create temp table ap as
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
       ,   Emp::int as emp
from apraw;

insert into ap (emp, startdate, enddate)
select 0::int, min(startdate), max(enddate) from ap;

create temp table apw as
select m.emp, m.fname, m.lname, m.wday, count(1)
  from clockmaster m, ap p
 where m.emp > 0
   and m.emp = p.emp
   and m.wday >= p.startdate
   and m.wday <= p.enddate
group by m.emp, m.fname, m.lname, m.wday    
  order by emp, wday;

create temp sequence x increment by 1 minvalue 1;

create temp table wdays as
select nextval('x') as rid, now()::date as day  from clockmaster limit 600;

alter table wdays add column dow int;
alter table wdays add column dame varchar(64);
alter table wdays add column call varchar(64);
alter table wdays add column pub varchar(64);

update wdays set day = p.startdate + (rid::int - 1)  from ap p where p.emp = 0;
update wdays set dow = extract(dow from day);  -- 1-5 is mon to fri
update wdays set dame = 
			case dow
			    when 0 then 'Sunday'
			    when 1 then 'Monday'
			    when 2 then 'Tuesday'
			    when 3 then 'Wednesday'
			    when 4 then 'Thursday'
			    when 5 then 'Friday'
			    when 6 then 'Satday'
			    when 7 then 'Pubday'
			end;  

create temp table apwdays as
select emp, wdays.*from wdays, ap where ap.emp > 0;

delete from apwdays using ap where apwdays.day > ap.enddate and ap.emp = 0;			
update apwdays set call = 'Absent';

update apwdays set pub = pubday from pub where day = pubdate;

update apwdays a set call = '' from apw w where a.emp = w.emp and a.day = w.wday;

create temp table apname as
select m.emp, max(m.fname) as fname
  from clockmaster m, ap p
 where m.emp > 0
   and m.emp = p.emp
   group by m.emp;

copy (select d.emp, fname, "day" as "Date", dame as "Day", pub as "Pub Holiday" 
        from apwdays d, apname n 
       where n.emp = d.emp
         and dow between 1 and 5 
         and call = 'Absent' 
       order by emp, day)
---   to '/home/gdt/RosesClockings/80-Absent-Person-Report.csv' with csv header;
  to E'c:\\clockings\\80-Absent-Person-Report.csv' with csv header;
  
select now() as "Absent Person Done";


