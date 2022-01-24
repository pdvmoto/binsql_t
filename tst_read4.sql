
-- find calibrated table (T).

-- set start point: time + dp-reads

-- do a heavy count, and make sure it is doing dp-reads

set timing on
set echo on

select /*+ parallel(t,4) full(t) */ count (*) from BISTO.H514_RESOURCE_TL_STEP1 t ;

select /*+ parallel(t,16) full(t) */ count (*) from BISTO.H514_RESOURCE_TL_STEP1 t ;

-- measure time

-- 
set timing off
set echo off

