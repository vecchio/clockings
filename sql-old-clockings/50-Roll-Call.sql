select now() as "Who's Absent Begin";

create temp table rdateraw (
today   varchar(64),
rdate   varchar(64)  );

copy rdateraw from E'c:\\clockings\\50-Roll-Call-Input.csv' with csv header;
-- copy rdateraw from '/home/gdt/RosesClockings/50-Roll-Call-Input.csv' with csv header;

create temp table rdate as
select case 
          when lower(today) = 'today' then now()::date
          else to_date( substring(rdate from 1  for 4) || ' ' ||
                        substring(rdate from 6  for 2) || ' ' ||
                        substring(rdate from 9  for 2) , 'YYYY MM DD')
       end as rdate
  from rdateraw;

create temp table rcall (
empc    varchar(64),
fname   varchar(64),
lname   varchar(64)  );

copy rcall from E'c:\\clockings\\EmpMaster.csv' with csv header;
-- copy rcall from '/home/gdt/RosesClockings/EmpMaster.csv' with csv header;

alter table rcall add column emp int;
update rcall set emp = empc::int;     

create temp table atwork as
select m.emp, m.fname, m.lname, m.wday, count(1)
  from clockmaster m, rcall r, rdate d
 where m.emp = r.emp
   and m.wday = d.rdate
group by m.emp, m.fname, m.lname, m.wday    
  order by emp, wday;

delete from rcall r using atwork a where r.emp = a.emp;

copy (select r.rdate as "Absent Date", c.emp as "Emp No", trim(c.fname) || ' ' || trim(c.lname) as "Employee" from rcall c, rdate r where emp > 0 order by emp)
  to E'c:\\clockings\\50-Roll-Call-Report.csv' with csv header;
  -- to '/home/gdt/RosesClockings/50-Roll-Call-Report.csv' with csv header;

select now() as "Absent Person Done";


