select now() as "Update Master Begin";

/* ===============================================================================
   read the latest clockings and get it into the master table.

*/

create temp table clockraw (
EmpNo        varchar(64),
FirstName    varchar(64),
Surname      varchar(64),
Department   varchar(64),
DepartmentID varchar(64),
Grouping     varchar(64),
TreeID       varchar(64),
Descr        varchar(64),
RecDateTime  varchar(64),
InOut        varchar(64),
Direction    varchar(64) );

copy clockraw from E'c:\\clockings\\10-update-Master-Input.csv' with csv header;
-- copy clockraw from  '/home/gdt/RosesClockings/10-update-Master-Input.csv' with csv header;

delete from clockraw where EmpNo ilike '%x%';

create temp table clockwork as
select empno::int as emp, firstname as fname, surname as lname, lower(inout) as dir,
 to_timestamp(
       substring(recdatetime from 1  for 4) || ' ' ||
       substring(recdatetime from 6  for 2) || ' ' ||
       substring(recdatetime from 9  for 2) || ' ' ||
       substring(recdatetime from 12 for 2) || ' ' ||
       substring(recdatetime from 15 for 2) || ' ' ||
       substring(recdatetime from 18 for 2)
       , 'YYYY MM DD HH24 MI SS') as clock
from clockraw;

/* clockmaster is only ever created once and must never be dropped
                                                  ================ 

create table clockmaster
(
  emp integer,
  "fname" character varying(64),
  "lname" character varying(64),
  dir character(3),
  clock timestamp without time zone,
  wday date
)

drop index clock_index
drop index wday_index 
create index clock_index on clockmaster (clock, emp)
create index wday_index on clockmaster (wday, emp)

select clock, emp, count(1) from clockmaster group by clock, emp having count(1) > 1 order by 2 desc

*/

/*
  remove stuff already there
*/

create index clock_indexw on clockwork (clock, emp);

delete from clockwork w using clockmaster m
 where w.emp   = m.emp
   and w.clock = m.clock;

insert into clockmaster (emp, fname, lname, dir, clock)
select emp, fname, lname, dir, clock from clockwork;

-- select count(1) from clockmaster where wday is null;

/* set wday for night shift  */
update clockmaster set wday = (clock::date) - interval '1 day'
 where wday is null
   and extract(hour from clock) >= 0
   and extract(hour from clock) < 5;

/* set wday for the rest */

update clockmaster set wday = clock::date
 where wday is null;   

vacuum full analyze clockmaster;
   
select now() as "Update Master Done";
