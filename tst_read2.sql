set feedback on
-- fill with data

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


commit ; 


set echo off
prompt
accept hit_enter prompt 'Same Data inserted into table... '


