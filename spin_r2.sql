
doc
	spin_redo.sql : generate redo for &1 sec

notes:
	- use SID to generate session-specific table, run  multiple sessions

#

select to_char ( sysdate, 'HH24:MI:SS' ) time from dual;


 -- use sid to identify a table + use it

define n_sec = &1

column mysid new_value mysid

select sys_context ( 'USERENV', 'SID' ) as mysid from dual ; 

prompt my sid is &mysid

set timing on

drop table t_mysid1_&mysid ;
drop table t_mysid2_&mysid ; 

--create table t_mysid1_&mysid as select * from all_tables ; 
create table t_mysid1_&mysid as select * from all_source ; 

-- make it bigger..
insert into t_mysid1_&mysid select * from t_mysid1_&mysid ; 
insert into t_mysid1_&mysid select * from t_mysid1_&mysid ; 
insert into t_mysid1_&mysid select * from t_mysid1_&mysid ; 

-- and have 2nd table to copy to/from
create table t_mysid2_&mysid as select * from t_mysid1_&mysid  ; 

@count t_mysid1_&mysid 



/* -- old stuff 
-- option for sess-specific table
define tabname = 't_redo_001'

-- two identical tables..
drop table t_redo1_001;
drop table t_redo2_001;
create table t_redo1_001 as select * from t_s ;
insert  into t_redo1_001 select * from t_s ; 
commit;
insert  into t_redo1_001 select * from t_s ; 
insert  into t_redo1_001 select * from t_s ; 

create table t_redo2_001 as select * from t_redo1_001 where 1=0 ;

-- -- -- */ 

declare 
	starttime	date ;
	str 		varchar2(1000);
	x 		number;
begin
  starttime := sysdate ;

    while (sysdate - starttime) < &n_sec / (24 * 3600) loop

      <<outer_for>>
      for i in 1..1000 loop
       	
          begin

            -- only do more work if still inside requested time-window.
            exit outer_for when (sysdate - starttime) > &n_sec / (24 * 3600);

            -- do some insert/delete 
            insert into t_mysid2_&mysid select * from t_mysid1_&mysid ;
            commit ; 

            -- only do more work if still inside requested time-window.
            exit outer_for when (sysdate - starttime) > &n_sec / (24 * 3600);

            delete from t_mysid2_&mysid ;
            commit ; 

          exception   -- overkill, for the moment...
            when others then null;
          end;

      end loop; -- i, named as "outer_for"

    end loop; -- while

end ;
/

set timing off
prompt .
select 'Clock Time: '|| to_char ( sysdate, 'HH24:MI:SS' ) dt from dual;
prompt .
prompt  __ __ __ __ spin_redo done. __ __ __ __
prompt . 
prompt .

