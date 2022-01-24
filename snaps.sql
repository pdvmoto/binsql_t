column dend_snap format A20
column end_time format A15

With snaps as
( select /*+ materialize */
  s2.end_interval_time
, s1.snap_id s1
, s2.snap_id s2
, s1.dbid, s1.instance_number
, round ( ( cast ( s2.end_interval_time as date) - cast (s1.end_interval_time as date) ) * 3600 * 24 ) as delta_time
--, s1.*, s2.*
from dba_hist_snapshot s1
  , dba_hist_snapshot s2
  , v$database db    -- ensure it is "this" dbid, add instance if needed.
where 1=1
and s1.snap_id + 1 = s2.snap_id  -- super simple solustion
and s1.dbid = s2.dbid
and s1.instance_number = s2.instance_number
and s1.startup_time = s2.startup_time
and s1.end_interval_time = s2.begin_interval_time
--and s1.dbid = db.dbid
and s2.begin_interval_time > trunc ( sysdate - 17 )  -- only recent
--order by s1.snap_id desc
) 
select   '@awr12 ' || s.s1 || ' ' || s.s2                          AS dend_snap
, to_char ( s.end_interval_time, 'DY DD HH24:MI' ) 			as end_time
from snaps s
order by s.s2 ; 
