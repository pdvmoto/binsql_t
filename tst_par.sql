
-- tst_par

-- test parallel hints, need repeatable sql, in about 15min.
--
-- todo: generate spoolfile with Date_time.
-- 
-- todo: also large bidwh.dwh_005_e31_detail_regel

spool tst_par_acc3

set autotrace off

@where 

set  timing on
set echo on
set autotrace on
set linesize 120


prompt .
prompt start a count with no hints, expect some DoP, parallel.
prompt . 

select count (*) from BIDWH.DWH_001_PROJ_SNAPSHOT_DET t ;

select count (*) from BISTO.H514_RESOURCE_TL_STEP1 t ;

prompt ===== with forced parallel,  DoP=2  ============================

select /*+ parallel(t, 2) */ count (*) from BIDWH.DWH_001_PROJ_SNAPSHOT_DET t ;

select /*+ parallel(t, 2) */ count (*) from BISTO.H514_RESOURCE_TL_STEP1 t ;

prompt ===== with foced parallel,  DoP=4  =========================

select /*+ parallel(t, 4) */ count (*) from BIDWH.DWH_001_PROJ_SNAPSHOT_DET t ;

select /*+ parallel(t, 4) */ count (*) from BISTO.H514_RESOURCE_TL_STEP1 t ;

prompt ===== with foced parallel,  DoP=8  =========================

select /*+ parallel(t, 8) */ count (*) from BIDWH.DWH_001_PROJ_SNAPSHOT_DET t ;

select /*+ parallel(t, 8) */ count (*) from BISTO.H514_RESOURCE_TL_STEP1 t ;

prompt ===== with forced non-parallel, and force a FTS (or cbo will scan indexes) ===== 

select /*+ full(t) noparallel(t) */ count (*) from BIDWH.DWH_001_PROJ_SNAPSHOT_DET t ;

select /*+ full(t) noparallel(t) */ count (*) from BISTO.H514_RESOURCE_TL_STEP1 t ;


set echo off
set autotrace off

@where

prompt now compare the timigs and the reported IO,
prompt then check the AWR..

spool off

