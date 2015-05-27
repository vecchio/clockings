#!/bin/sh

pg_dump --table=clockmaster --column-inserts clock_dev > clockmaster-mysql.sql
