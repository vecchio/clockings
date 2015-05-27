/*
   -- run this only one to get old clockmaster in

delete from clockings where workday < '2010-01-01';
delete from clockmaster where clock < '2010-01-01';

insert into clockings (finger, name, surname, direction, clocking, created_at, updated_at)
  select emp, fname, lname, dir, clock, now(), now() from clockmaster;

update clockings set workday = (clocking::date) - interval '1 day'
where workday is null
      and extract(hour from clocking) >= 0
      and extract(hour from clocking) < 5;

update clockings set workday = clocking::date
where workday is null;

*/

/* ===============================================================================
   read the latest clockings and get it into the master table.

*/

create temp table clockraw (
FingerNo        varchar(64),
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

-- copy clockraw from E'c:\\clockings\\10-update-Master-Input.csv' with csv header;
copy clockraw from  '/home/g/a/p/clockings/sql/import.csv' with csv header;

delete from clockraw where fingerNo ilike '%x%';

create temp table clockwork as
select fingerno::int as finger, firstname as fname, surname as lname, lower(inout) as dir,
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
  finger integer,
  "fname" character varying(64),
  "lname" character varying(64),
  dir character(3),
  clock timestamp without time zone,
  wday date
)

drop index clock_index
drop index wday_index
create index clock_index on clockmaster (clock, finger)
create index wday_index on clockmaster (wday, finger)

select clock, finger, count(1) from clockmaster group by clock, finger having count(1) > 1 order by 2 desc

*/

/*
  remove stuff already there
*/

create index clock_index on clockwork (clock, finger);

delete from clockwork w using clockings m
 where w.finger = m.finger
   and w.clock  = m.clocking;

insert into clockings (finger, name, surname, direction, clocking, created_at, updated_at)
select finger, fname, lname, dir, clock, now(), now() from clockwork;

-- select count(1) from clockmaster where wday is null;

/* set wday for night shift  */
update clockings set workday = (clocking::date) - interval '1 day'
 where workday is null
   and extract(hour from clocking) >= 0
   and extract(hour from clocking) < 5;

/* set wday for the rest */

update clockings set workday = clocking::date
 where workday is null;

vacuum full analyze clockings;


