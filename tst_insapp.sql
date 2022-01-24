

set timing on
set autotrace on 
set echo on

alter session enable parallel dml ; 

drop table t_in_app;

create table t_in_app noparallel  
as select *
from bisto.FCT_001_SNAPSHOT_ACTUALS a
where 1=0;


insert /* p1 */ into t_in_app a
select /*+ NOPARALLEL ( a)  */ *
from bisto.FCT_001_SNAPSHOT_ACTUALS a
where rownum < (1024 * 1024 * 1 ) ; 


drop table t_in_app;

create table t_in_app  parallel 16
as select *
from bisto.FCT_001_SNAPSHOT_ACTUALS a
where 1=0;

insert /* p16 */ into t_in_app 
select /* PARALLEL ( 16 )   */ *
from bisto.FCT_001_SNAPSHOT_ACTUALS a
where rownum < (1024 * 1024 * 1 ) ; 

-- make sure we dont leave locks
commit; 

