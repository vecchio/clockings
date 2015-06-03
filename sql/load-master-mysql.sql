load data local infile '/home/g/a/p/clockings/sql-work/clockmaster-01jun2015.csv'
into table clockings
fields terminated by ','
ignore 1 lines
(finger, name, surname, direction, clocking, workday);