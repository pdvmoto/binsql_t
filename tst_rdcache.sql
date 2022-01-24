column object_name format A30
column mb_in_cache format 99,999.000

-- check if data is in cache..

select o.object_name, count (*) * 8196/(1024*1024) as mb_in_cache
from v$bh b 
, dba_objects o
where b.objd = o.data_object_id
and object_name = 'DWH_005_E31_DETAIL_REGEL'
group by o.object_name
order by 2 ; 

-- count using paralle

select /*+ full(t) parallel(t) */ count (*) from bidwh.dwh_005_e31_detail_regel t 
where wkr_detail is not null; 
@x

-- re-check cache

select o.object_name, count (*) * 8196/(1024*1024) as mb_in_cache
from v$bh b 
, dba_objects o
where b.objd = o.data_object_id
and object_name = 'DWH_005_E31_DETAIL_REGEL'
group by o.object_name
order by 2 ; 

-- count using noparr
select /*+ full(t) noparallel(t) */ count (*) from bidwh.dwh_005_e31_detail_regel t 
where wkr_detail is not null;
@x 

-- re-check cache
select o.object_name, count (*) * 8196/(1024*1024) as mb_in_cache
from v$bh b 
, dba_objects o
where b.objd = o.data_object_id
and object_name = 'DWH_005_E31_DETAIL_REGEL'
group by o.object_name
order by 2 ; 

