-- demo that comments do not harm hints.

create table tst_wm as select object_id, owner, object_name from dba_objects ; 


set autotrace on explain

select /* q0 */ /*+ noparallel(t)    */ count (*) from tst_wm  t;

select /* q1 */ /*+   parallel(t, 4) */ count (*) from tst_wm t ;

set autotrace off

prompt never drop unless  you are Sure you created it..
prompt drop table tst_wm;
