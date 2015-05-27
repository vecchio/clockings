insert into clockings (finger, name, surname, direction, clocking, workday)
    select emp, fname, lname, dir, clock, wday
      from clockmaster;