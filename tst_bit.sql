

set timing on
set echo on 

set autotrace on

drop table tst_001 ;

create table tst_001 as select * from bisto.fct_001_snapshot_actuals where rownum < (1 * 1024 * 1024 );

create bitmap index tst_001_b3 on tst_001 ( keyref3 ) 
--parallel 2 
--tablespace bisti_data
;

create bitmap index tst_001_b2 on tst_001 ( keyref2 ) ;

set autotrace off



                                                           *