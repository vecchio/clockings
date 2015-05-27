/* 
select * from payments limit 50;
select * from payments order by workday desc limit 50;
select count(1) from payments limit 5;
select * from clockings order by workday limit 500;
truncate table payments ;

delete from clockings where workday < '2010-01-01';
delete from clockmaster where clock < '2010-01-01';

select * from clockmaster order by clock limit 20;
select *, (s_date + integer 10) from daterange;
select * from daterange;
-- ---------------------------------------------------------------------------------

create temporary table daterange as
select min(workday) as s_date, current_date as e_date from clockings;
*/

-- ---------------------------------------------------------------------------------
create temporary table daterange as
select max(workday) as s_date, current_date as e_date from payments;
update daterange set e_date = date_add(s_date, interval 1000 day);

delete from payments where workday >= (select s_date from daterange );

create temporary table clockinout as
  select i.finger, i.name, i.surname, i.workday, i.direction as idir, i.clocking as iclock, o.direction as odir, o.clocking as oclock
  from clockings i, clockings o, daterange d
  where i.workday between  d.s_date and d.e_date
        and o.workday between  d.s_date and d.e_date
        and i.finger = o.finger
        and i.workday = o.workday
        and i.direction = 'in'
        and o.direction = 'out'
        and o.clocking  > i.clocking
  order by finger, iclock, oclock;

delete from clockinout where oclock <  iclock;


-- remove multiple clock outs
create temporary table clockinoutclean_o as
  select finger, name, surname, workday, idir, iclock, odir, min(oclock) as oclock
  from clockinout
  group by finger, name, surname, workday, idir, iclock, odir
  order by finger, iclock, oclock;

-- remove multiple clock ins
create temporary table clockinoutclean as
  select finger, name, surname, workday, idir, min(iclock) as iclock, odir, oclock
  from clockinoutclean_o
  group by finger, name, surname, workday, idir, oclock, odir
  order by finger, iclock, oclock;

create temporary table clockinoutduration as
  select *, time_to_sec(timediff(oclock,iclock)) as dur
  from clockinoutclean
  order by finger, iclock;

create temporary table clockempday as
  select  finger, name, surname, workday,
    sec_to_time(sum(dur)) as dur, count(1) as entries, cast(0 as decimal(8,2)) as pay,
    case when extract(hour from min(iclock)) >= 16 and extract(minute from min(Iclock)) >= 15
    then 1 else 0
    end as night,
    time(min(iclock)) as arrive
  from clockinoutduration
  group by finger, name, surname, workday
  order by finger, workday;

update clockempday set pay = cast((((extract(hour from dur) * 60) + (extract(minute from dur) + 50))/60) as decimal(8,2));
update clockempday set pay = truncate(pay, 0) 	where (pay - truncate(pay, 0)) between 0.0 and 0.11;
update clockempday set pay = (truncate(pay, 0)+ 0.25)  where (pay - truncate(pay, 0)) between 0.12 and 0.25;
update clockempday set pay = (truncate(pay, 0)+ 0.25)  where (pay - truncate(pay, 0)) between 0.26 and 0.36;
update clockempday set pay = (truncate(pay, 0)+ 0.5) 	where (pay - truncate(pay, 0)) between 0.37 and 0.5;
update clockempday set pay = (truncate(pay, 0)+ 0.5) 	where (pay - truncate(pay, 0)) between 0.51 and 0.61;
update clockempday set pay = (truncate(pay, 0)+ 0.75)  where (pay - truncate(pay, 0)) between 0.62 and 0.75;
update clockempday set pay = (truncate(pay, 0)+ 0.75)  where (pay - truncate(pay, 0)) between 0.76 and 0.86;
update clockempday set pay = (truncate(pay, 0)+ 1.00)  where (pay - truncate(pay, 0)) > 0.86;

insert into payments (finger, pay_duration, workday, duration, entries, night, arrive)
  select finger, pay, workday, dur, entries, night, arrive from clockempday;

