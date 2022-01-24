set linesize 160
set trimspool on
set feedb off
set ver off
set timing off

column sql_text    format A80

column username    format A10
column buff_gets   format 999999999
column execs       format 999999
column per_exe     format 9999,999
column hash_value  format 99999999999
column sql_id      format A14
column chld        format 9999

column numrows     format 999,999
column cpu_sec     format 9999.99
column ela_sec     format 9999.99
column every_x_sec format 9999.99

column chld               format 99
column datatype           format A15
column bind_variable      format A15
column bind_value         format A20
column bind_vals          format A60 trunc


column operation   format A35
column options     format A15
column on_object   format A35
column cost        format 9999999

column acc_pred     format A30 
column fltr_pred    format A30 


column explout format A60 newline


spool sql_&1 

@where

prompt
prompt
prompt ---------------------------------------------------------------------

-- prompt statement, statistics and explain-plan from sh-pool....

-- some generic numbers, akin to statpack.

select u.username
, a.executions       execs
, a.buffer_gets      buff_gets
, a.buffer_gets/(decode ( executions, 0, 1, executions )) as per_exe , first_load_time
, rows_processed     numrows
, sql_id
, child_number chld
--, a.cpu_time/(1000000) as cpu_sec, a.elapsed_time/(1000000) as ela_sec --, to_char ( ( sysdate - to_date ( a.first_load_time, 'YYYY-MM-DD/HH24:MI:SS' )  ) * 24 * 3600 / a.executions, '99,999.99' ) as every_x_sec --, a.* 
from v$sql a 
, dba_users u 
where u.user_id = a.parsing_user_id 
and a.sql_id = '&1'
order by sql_id, child_number
/



set head off

select 
  'Column          Value'
, '--------------  -----------'                as explout
, 'User          : ' ||  u.username            as explout
, 'sql_id =      : ' || sql_id                 as explout
, 'child_number  : ' || child_number           as explout
, 'plan_hash     : ' || plan_hash_value        as explout
, 'Executions    : ' || a.executions           as explout   
, 'Rows processed: ' || rows_processed         as explout
, 'Buffer_gets   : ' || a.buffer_gets          as explout
, 'disk_reads    : ' || disk_reads             as explout
, 'bufgets/exe   : ' || round ( a.buffer_gets/(decode ( executions    , 0, 1, executions     )), 2)  as explout
, 'bufgets/row   : ' || round ( a.buffer_gets/(decode ( rows_processed, 0, 1, rows_processed )), 2)  as explout
, 'Fist load     : ' || first_load_time        as explout
, 'elapsed (sec) : ' || round ( elapsed_time/1000000                                           , 2) as explout
--, a.cpu_time/(1000000) as cpu_sec, a.elapsed_time/(1000000) as ela_sec --, to_char ( ( sysdate - to_date ( a.first_load_time, 'YYYY-MM-DD/HH24:MI:SS' )  ) * 24 * 3600 / a.executions, '99,999.99' ) as every_x_sec --, a.* 
from v$sql a 
, dba_users u 
where u.user_id = a.parsing_user_id 
and a.sql_id = '&1'
order by sql_id, child_number
/

-- added sql-freq + history from dba_hist_%

column time       format A13
column execs      format 99999
column ela        format 999,999
column sec_px     format 99999
column get_px     format 99,999,999
column g_pr       format 99999
column nr_rows    format 99,999,999
column pln_hv     format A10

set pagesize 50
set heading on

select to_char ( sn.end_interval_time , 'DDMON HH24:MI') /* || to_char ( sn.instance_number, '9') */ as Time
, sq.executions_delta     execs
, sq.buffer_gets_delta    buff_gets
, round ( elapsed_time_delta / ( decode ( executions_delta,     0, 1, executions_delta     ) * 1000000), 2 )   as sec_px -- (1000 * 1000 )
, round ( buffer_gets_delta  / ( decode ( executions_delta,     0, 1, executions_delta     )          ), 2 )   as get_px -- (1000 * 1000 )
, rows_processed_delta nr_rows
, round ( buffer_gets_delta  / ( decode ( rows_processed_delta, 0, 1, rows_processed_delta )          ) , 2)      g_pr -- , elapsed_time_delta ela
, to_char ( sq.plan_hash_value )  as pln_hv
--, substr ( sx.sql_text, 1, 20) sqltxt
--, sq.* 
from dba_hist_sqlstat  sq 
   , dba_hist_snapshot sn
   , dba_hist_sqltext  sx
where sn.snap_id = sq.snap_id
  and sn.dbid = sq.dbid
  and sn.instance_number = sq.instance_number 
  and sq.sql_id = '&1'
  and sq.sql_id = sx.sql_id
  and sq.dbid = sx.dbid
    and sq.executions_delta > 0 
order by sn.snap_id, sn.instance_number ; 

-- added sql-freq + history


/**** 
-- one-off for pcs only: fetch old data from sqh-tables..
select to_char ( sn.end_interval_time , 'DDMON HH24:MI') 
-- || to_char ( sn.instance_number, '9')  
  as Time
, sq.executions_delta     execs
, sq.buffer_gets_delta    buff_gets
, round ( elapsed_time_delta / ( decode ( executions_delta,     0, 1, executions_delta     ) * 1000000), 2 )   as sec_px -- (1000 * 1000 )
, round ( buffer_gets_delta  / ( decode ( executions_delta,     0, 1, executions_delta     )          ), 2 )   as get_px -- (1000 * 1000 )
, rows_processed_delta nr_rows
, round ( buffer_gets_delta  / ( decode ( rows_processed_delta, 0, 1, rows_processed_delta )          ) , 2)      g_pr -- , elapsed_time_delta ela
, substr ( sq.plan_hash_value, 1, 6 ) || '..' as pln_hv
--, substr ( sx.sql_text, 1, 20) sqltxt
--, sq.* 
from sqh_sqlstat  sq 
   , sqh_snapshot sn
   , sqh_sqltext  sx
where sn.snap_id = sq.snap_id
  and sn.dbid = sq.dbid
  and sn.instance_number = sq.instance_number 
  and sq.sql_id = '&1'
  and sq.sql_id = sx.sql_id
  and sq.dbid = sx.dbid
  --and sq.executions_delta > 0 
order by sn.snap_id, sn.instance_number ; 

*****/

set head off

-- sqltxt from sh-pool memory

select  t.sql_text
from v$sqltext t
where sql_id = '&1'
order by piece
/

set head on

-- try picking bind-vars from memory, only cursors 0+1

select  --bvc.sql_id
  bvc.child_number     chld
--, bvc.name             bind_variable
--, bvc.datatype_string  datatype
--, bvc.value_string     bind_value
--bvc.*
--ANYDATA.AccessTimestamp(bvc.value_anydata)
-- ANYDATA.Accessdate(bvc.value_anydata)
, ' ' ||  lpad( replace ( bvc.name, ':', ':b' ), 5) ||  ' := '
  || decode ( substr ( bvc.datatype_string, 1, 3)
            ,  'NUM' , nvl ( bvc.value_string, '''''' )
            ,  'VAR' , '''' || bvc.value_string || ''''
            ,  'DAT' , '      to_date ( ' || '''' || ANYDATA.Accessdate(bvc.value_anydata) || ''', ''YYYY-MM-DD HH24:MI:SS'' ) '
            ,  'TIM' , ' to_timestamp ( ' || '''' || ANYDATA.AccessTimestamp(bvc.value_anydata) || ''', ''YYYY-MM-DD HH24:MI:SS'' ) '
            ,  bvc.value_string
            ) || '  ;'   as bind_vals
from v$sql_bind_capture bvc
where 1=1
and child_number < 2
and sql_id = '9dz4twussxjg7'
order by child_number, name ;

/****** old stuff ****

select -- bvc.sql_id,
  bvc.child_number     chld
, bvc.name             bind_variable
, bvc.datatype_string  datatype
, bvc.value_string     bind_value
--, bvc.*
from v$sql_bind_capture bvc
where 1=1
and sql_id = '&1'
order by child_number, name;

**** */

-- explain from shared-pool

set linesize 190
set trimspool on

/** skip this, dbms_xplan is more readable ***

select
  cost
, decode ( depth, 0, '', rpad (' ', depth*1, ' ') )
|| rtrim  ( operation, 30)  as operation
,  rtrim ( options, 15) as options
,  rtrim( object_owner || '.' || object_name || ' ' || optimizer || '
' , 30 )  as on_object
, v.access_predicates as acc_pred, v.filter_predicates as fltr_pred 
--, v.* 
from v$sql_plan v where sql_id = '&1' --'18979282' --'15494617'
order by hash_value, child_number, address, id 
/

**** skipped now ****/

prompt '--------- plans from memory -- '

-- explain from memory if available

SELECT plan_table_output FROM table(DBMS_XPLAN.DISPLAY_CURSOR('&1'));

-- explained from AWR, whatever is available

prompt '--------- plans from awr -- '

select plan_table_output from table (dbms_xplan.display_awr('&1'));

prompt .
prompt .
prompt Blocker-info from ASH (last 24 hrs??)
prompt blocks are counts, only indicative, check times in AWR.

select count (*) as nr_waits
, ash.event
, ash.blocking_session as blocker
--, ash.* 
from dba_hist_active_sess_history ash
where ash.sql_id = '&1'
and ash.sample_time >  (sysdate - 1 )
and blocking_session is not null 
group by ash.event, ash.blocking_session
order by 1 desc ;

-- more wait-details..
select ash1.sql_id sql_id, ash2.sql_id blocker_sql
,  ash1.event wating_event
,  ash2.event blocker_event
--, ash1.* 
from dba_hist_active_sess_history ash1
, dba_hist_active_sess_history ash2
where 1=1 -- session_id = 1348 
and ash1.snap_id = ash2.snap_id
and ash1.dbid = ash2.dbid
and ash1.instance_number = ash2.instance_number 
and ash1.sample_id = ash2.sample_id
and ash1.blocking_session = ash2.session_id 
and ash1.sample_time >  (sysdate - 1 )
and ash1.sql_id = '&1'
and ash1.blocking_session is not null 
order by ash1.snap_id, ash2.sample_time  ;


prompt . 
prompt . output in :
prompt ed sql_&1..lst
prompt .
spool off



