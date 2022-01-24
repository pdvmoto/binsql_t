column object_name format A30
column mb_in_cache format 99,999.000

select o.object_name, o.object_type, count (*) * 8196/(1024*1024) as mb_in_cache
from v$bh b 
, dba_objects o
where b.objd = o.data_object_id
and o.object_name like upper ( '%&1%' )
group by o.object_name, object_type
order by 3 ; 