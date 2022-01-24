

/* 
 tst_redo.sql: demonstrate max-redo volume.. run multiple sessions, use AWR.

story to tell in ppt :
 - Find out how Much redo this system can do, if no other activ.. 
 - that nr is the upper-limit, expect redo-waits.
 - how: just insert + delete data at high rate.

Demo-notes:
 - none yet 

*/


-- table T and optionally PT.. allow for some partitioning.. ?
-- size it to be easily re-startable and no wait times.
-- name partitions explicit to allow easy drop.
-- 

-- easier to read.
set sqlprompt "SQL> " 

-- two tables, partitioned and conventional, for comparison
-- also consider: base-table with data-set for re-deployments

set timing on

drop table pt ; 
drop table  t ; 

purge recyclebin ; 

clear screen

prompt  
prompt ____  original demo starts here... _____
prompt 

set echo on

create table pt 
( id                number ( 9,0)    -- the PK and partitioning-key.
, active            varchar2 ( 1 )   -- Y/N, show small set of Active.
, amount            number ( 10,2 )  -- supposedly some amount of money.
, dt                date             -- a date, case we want history stuff 
, payload           varchar2 ( 200 ) -- some text
, filler            varchar2 ( 750 ) -- some data to create 1K recordsize
)
partition by range ( id )  interval ( 1000000 ) 
(   partition pt_1 values less than ( 1000000 )  
  , partition pt_2 values less than ( 2000000 ) 
  , partition pt_3 values less than ( 3000000 ) 
  , partition pt_4 values less than ( 4000000 ) ) ;

set echo off


--
-- Create identical table T, non-partitioned
-- 
create table t 
( id number ( 9,0)   
, active            varchar2 ( 1 )  
, amount            number ( 10,2 )
, dt                date          
, payload           varchar2 ( 200 ) 
, filler            varchar2 ( 750 ) 
) ;

set echo on

--
-- fill with deliberately funny, compressible data
-- 4 partitions, 40K records was nice number for timing, effort, demo.. 
--
insert into pt
select 
   trunc ( rownum -1)                               -- sequene...
,  decode ( mod ( rownum, 10000), 0, 'Y', 'N' )     -- every 1/1000 active=Y
,  mod ( rownum-1, 10000 ) / 100                    -- 0-100, two decimals
,  (sysdate - mod ( rownum, 1000) )                              -- some dates
,  rpad ( to_char (to_date ( trunc ( mod ( rownum, 1000) ) + 1, 'J'), 'JSP' ), 198) -- words
,  rpad ( ' ', 750 )                                -- blanks
from dual
connect by rownum <= (7 * 1024 * 1024 )   -- should result in 8 partitions?
;

commit ; 


--
-- and copy into conventional table.
--
insert into t select * from pt ;

-- show stats, to get some idea.

EXEC DBMS_STATS.gather_table_stats(user, 'PT', null, 1);
EXEC DBMS_STATS.gather_table_stats(user, 'T' , null, 1);

set echo off

column table_name format A20  
column part_name  format A20 
column hv format 999999 head High_val

select table_name, '-' as part_name, num_rows 
from user_tables
where table_name like 'T'
order by table_name ; 

select table_name, partition_name part_name, num_rows 
from user_tab_partitions
where table_name like 'PT%'
order by table_name, partition_name ; 

prompt 
prompt
prompt (and dont forget to set terminal to 128 x 34 and large font...)
prompt
prompt
prompt
prompt 
prompt Demo Ready... : 
prompt 
prompt We have two tables 
prompt T    conventional, all records in 1 table-segment 
prompt PT   partitioned, with partitions 
prompt 
prompt From here, start a loop of X seconds (arg1) to ins/commit/del/commit data.
prompt 
prompt 


