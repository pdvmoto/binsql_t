
doc
	spin_pio.sql : generate PIO for &1 sec

notes:
	- if SGA is large compared to accessible data on disk.. this wont work well.
	- any long table with large records may upset the specified time.
#


exec dbms_application_info.set_module  ( module_name => 'spin_p2', action_name => 'benchmark' ) ;

-- select to_char ( sysdate, 'HH24:MI:SS' ) from dual;

set serveroutput on

declare 
	starttime	date ;
	str 		varchar2(1000);
        start_dt        date ; 
	n_sec           number(9,2) ; 
	nrows 		number;
begin
  starttime := sysdate ;

    while (sysdate - starttime) < &1 / (24 * 3600) loop

      <<outer_for>>
      for i in 1..&1 loop
       	for t in (select owner, table_name from all_tables 
                  where (owner,table_name) not in (select owner,table_name from all_external_tables)
                  and num_rows > (10*1024*1024 )
                  order by owner, table_name ) loop

          begin

            -- only do more work if still inside requested time-window.
            exit outer_for when (sysdate - starttime) > &1 / (24 * 3600);

            start_dt    := sysdate ;

            -- do some counting, but limit to N rows to avoid runaways on large tables. 
            execute immediate 'select /*t8*/ /*+ full(t) parallel(t,8) */ count(*) from '||t.owner||'.'||t.table_name||' t where rownum < 1000000000' into nrows;

	    n_sec := (sysdate - start_dt ) * ( 60 * 60 * 24 ) ; 

            dbms_output.put_line ( '..found '||t.owner||'.'||t.table_name||': ' || nrows || '; in ' || n_sec || ' seconds.' ) ; 

          exception   -- overkill, for the moment...
            when others then null;
          end;

        end loop; -- t
      end loop; -- i, named as "outer_for"

    end loop; -- while

end ;
/


exec dbms_application_info.set_module  ( module_name => 'SQL*Plus', action_name => ' ' ) ;

-- select to_char ( sysdate, 'HH24:MI:SS' ) from dual;

--@sleep &1

--select to_char ( sysdate, 'HH24:MI:SS' ) from dual;

