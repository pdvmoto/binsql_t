
-- tst_read : how fast can we read a TB table.. (and sum it, and do it again)

-- find big(gest) tables.. (may be partitioned): make 2 copies, make sure not in cache..?
-- read-count-FULL.. with 1, 2 4 8 PQ.
-- verify it is Physical read... (autotrace)


-- start with conventional table, and use hints to PX..
-- verify the actual reads are done
-- verify it is dp-reads
-- verify timing.. preferably just under 15min ? 
-- Test with Part-table.. 






/* 

Demo-notes:
 - screen 128 x 34 , need wide screen for explain in demo_1

 - re-test against 18.x and 12.1.


notably
 - table with pk and payload and "compressible filler", (local) index on payload
 - generate  records.
 - demo delete from large table  (time + redo)
 - demo drop partition, see how fast?

extras
 - pk with yyyymmddSSS+sequence
 - locking, how long when delete, how long when drop/exchange..

Check:
 - on-line operations for partitioning ? 
 - license for partitioning still an issue ? 
 - filtered-partition operations - check+test+demo ?
 - compressed partitions, do they also use less memory ? 

 - note: logfile > 100, slow creation of tables: if LOG=16M to compare to PG..

test
 - date+seq idea for pk
 - volume of pk as integer, string or even timestamp, any impact ? 
 - function to create pk ? 

demo-items:
 - measure redo-volume, verify with log-switches or WAL files (16M files)
 - check_redo : report redo volume since last, minus 0.4 kb ? 
 - insert records into table and/or some partitions
 - remove via delete and via partition: no redo!
    notably on delete of "1 month" or one partition.
 - small partitions: easy full-scan.
 - compress old partitions (rebuild index ?), need to alter+move+rebuild-idx.
 - read-only partitions (tablespace and/or partition)
 - looping over many partitions.. extra effort even if indexed


items needed: 
 - an insert-routine for (trickle) inserts
 - a delete-routine for (trickle) deletes
 - a key-generator YMD-seq

create sequence pt_seq start with 1 maxvalue 99999 cycle;

with series as (
select rownum num 
,  to_char (to_date ( rownum, 'J'), 'JSP' ) 
from dual 
connect by rownum < 10 )
select * from series ; 

using YYYY DDD HH24MISS 
for   2020 366 23:59:59
we end up wth a ridiculous high nr ? 2 Trillion ? 
2.019.294.175.716

add to that 6 digit for Seq, and .. 25 digit precision, just inside oracle..

....,....1....,....2....,
2.020.366.235.959.000.000

assume: 1000 rec/sec -> 100M / day

100M = 8 or 9 digits (inside 1 day).


stored by day:  
5 or 8 digits for the day
8: YYYYMMDD
5: YYDDD 
then 8 digits for the seq in the day.
total 16  digits


10: YYYYMMDDHH 
stored by hr : 6 digits per hr..
same.. 16 digits.

stored by sec: 
14: YYYYMMDDHHMISS 
plus 3 or 4 digits for seq (999 /sec) 
total 15 or 16  digits, same, so might as well be clear and use YMD-HMS

in all cases: 16 digits...
but 16 digits is still only half of a GUID

Q: 
 - what if we put Day as interger, and intra-day as fraction behind dec-sep.?


Research Topics for Audience
 - would an artificial key on date-nr work ? YYY DDD HHMIDD + seq, avoid Global IDX.
 - what about ultra small partitions ? Compressed ?
 - any practical experience with mixed internal/external partitions ? 
 - 
 - 


create replace table pt2
( id number(25, 0) 
, payload varchar2/(1000)
)

*/

-- drop create here

-- table with integer-key, add some values, 
-- size it to be easily re-startable and no wait times
-- but allow to fill to significant size
-- 

drop table    t ; 
drop sequence t_seq ; 

purge recyclebin ;

create sequence t_seq ;

create table    t 
( id number ( 9,0)   
, active            varchar2 ( 1 )  
, amount            number ( 10,2 )
, dt                date          
, payload           varchar2 ( 200 ) 
, filler            varchar2 ( 750 ) 
) ;


create unique index t_pk on  t ( id ) ; 

alter table t add constraint t_pk primary key ( id ) ;

set echo off
prompt 
accept hit_enter prompt 'Check the indentical, conventional table T... '


set feedback on

clear screen

set echo on

--
-- fill with deliberately funny, compressible data
--
insert into t
select 
   t_seq.nextval                                    -- sequene...
,  decode ( mod ( rownum, 10000), 0, 'Y', 'N' )     -- every 1/1000 active=Y
,  mod ( rownum-1, 10000 ) / 100                    -- 0-100, two decimals
,  (sysdate - rownum )                              -- some dates
,  rpad ( to_char (to_date ( trunc ( rownum ), 'J'), 'JSP' ), 198) -- words
,  rpad ( ' ', 750 )                                -- blanks
from dual
connect by rownum <= 500000 ;

set echo off
prompt
accept hit_enter prompt 'Same Data inserted into table... '

clear screen

set echo on

--
--  add extra index for realistic effect, and gather stats..
-- 

create index  t_i_pay  on  t ( payload, filler, amount) ;

EXEC DBMS_STATS.gather_table_stats(user, 'T' , null, 1);

set echo off

column table_name format A20  
column part_name  format A20 
column hv format 999999 head High_val

select table_name, '-' as part_name, num_rows 
from user_tables
where table_name like 'T'
order by table_name ; 


prompt 
prompt
prompt (and dont forget to set terminal to 128 x 34 and large font...)
prompt
prompt
prompt
prompt 
prompt Demo Ready... : 
prompt 
prompt We have table 
prompt T    conventional, all records in 1 table-segment 
prompt 





