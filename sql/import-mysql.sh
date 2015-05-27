#!/bin/sh
#psql clock_dev -f /home/g/a/p/clockings/sql/import.sql
mysql clock_dev < /home/g/a/p/clockings/sql/process-mysql.sql
