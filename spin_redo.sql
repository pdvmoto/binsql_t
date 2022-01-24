
doc
	spin_redo.sql : generate redo for &1 sec

notes:
	- use SID to generate session-specific table, run  multiple sessions

#

-- select to_char ( sysdate, 'HH24:MI:SS' ) from dual;

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

declare 
	starttime	date ;
	str 		varchar2(1000);
	x 		number;
begin
  starttime := sysdate ;

    while (sysdate - starttime) < &1 / (24 * 3600) loop

      <<outer_for>>
      for i in 1..&1 loop
       	
          begin

            -- only do more work if still inside requested time-window.
            exit outer_for when (sysdate - starttime) > &1 / (24 * 3600);

            -- do some insert/delete 
            insert into t_redo2_001 select * from t_redo1_001 ;
            commit ; 

            -- only do more work if still inside requested time-window.
            exit outer_for when (sysdate - starttime) > &1 / (24 * 3600);

            delete from t_redo2_001 ;
            commit ; 

          exception   -- overkill, for the moment...
            when others then null;
          end;

      end loop; -- i, named as "outer_for"

    end loop; -- while

end ;
/

-- select to_char ( sysdate, 'HH24:MI:SS' ) from dual;

--@sleep &1

--select to_char ( sysdate, 'HH24:MI:SS' ) from dual;

