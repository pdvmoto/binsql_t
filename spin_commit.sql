
set doc off
set serveroutput on 

DOC

	spin.sql : spin for &1 sec

Simple version:
    drop table mytimer ;
    drop table abc;
    drop table def;

    create table mytimer as select sysdate as tmstmp from dual ;
    create table abc as select * from dba_users ;
    create table def as select * from abc ; 

Next version:
1. larger table with PK and FK indexes to be realistic, variable payload to check size.
2. every SID works on separate set (parent-key can be SID)
3. test inserts, updates, delete (use dbms-random to pick records)

setup of test:
 - table tst_lfs ( par_id number, chk_id number, payload varchar2 (4000) )
 - the nr records N, and payload size can vary

logic of test:
 - start of test, enter N records in table, use SID for parent-id, and 1-N for chk
 - seed random with time-seconds
 - while-time (seconds)
    counter++
     Random 1 delete + commit, keep the id for re-insert
     Random 1 update + commit 
     Random 1 re-insert + commit
 - dbms-output to show numbers, optional: including "errorcount"

todo:
 - use exec immedaite to do commit/wait/batch
 - better report data
 - report data from session and system
 - report values of commit_write/commit_logging
 - re-code in phyton

functions + procs wanted:
 - get_param from sess/sys
 - get_event from ses/sys
#


-- select to_char ( sysdate, 'HH24:MI:SS' ) from dual;

/*** 
    --  use this to create the data-table

    drop table tst_lfs ;
    create table tst_lfs (
        id  number
      , par_id number
  , payload varchar2(4000)
    );

    create unique index tst_lfs_pk on tst_lfs ( par_id, id ) ; 
    alter table tst_lfs add constraint tst_lfs_pk primary key ( par_id, id ) using index ;


***/

set serveroutput on
set timing on

declare 

	starttime	date ;
    n_counter   number ; 
    n_sid       number ; 
    n_records   number := 1000 ; 
    n_recid     number ; -- determine random 1-1000, rec to process

    n_stat_commits number ;
    n_ev_nrlfs     number ;
    n_secs         number ; -- seconds input or measured.

/************************ get_param **********************************************/
-- a function to get parameters ( initially for info-display)
FUNCTION get_param ( 
        sys_or_ses  in varchar2 
      , param       in varchar2) 
    RETURN varchar2 
AS

  vc_retval varchar2(200);

BEGIN
  IF     sys_or_ses = 'SYS'      THEN 
  BEGIN  
    select value into vc_retval from v$parameter where name = param ; 
    --vc_retval := 'SYS' || ' value of : ' || param || ' is [' || vc_retval || ']';
  END;  
  ELSIF sys_or_ses = 'SES'      THEN 
  BEGIN
    vc_retval := 'SES' || ' value of : ' || param || ' is ...';
    null ;
  END ;
  ELSE                            
    vc_retval := 'unknown ses or sys for value of ' || param || ' (error) ...';
  END IF; 

  return vc_retval ;
END;


/************************ acutal code block ******************************************/
begin

    -- get sid and n-records
    select  USERENV('SID') into n_sid from dual ; 
    n_secs := &1 ; 

	starttime := sysdate ;
    n_counter := 0; 

    dbms_output.put_line ( 'spin_commit: start, sid: ' || n_sid || ' n_records/par: ' || n_records ) ;

    dbms_output.put_line ( 'spin_commit: param commit_logging = [' 
        || get_param ( 'SYS', 'commit_logging' ) || ']' ) ;

    dbms_output.put_line ( 'spin_commit: param commit_wait    = [' 
        || get_param ( 'SYS', 'commit_wait' )  || ']') ;

    dbms_output.put_line ( 'spin_commit: param commit_write   = [' 
        || get_param ( 'SYS', 'commit_write' )  || '] (deprecated)' )  ;

    --  generate n records, catch doubles to allow multipel runs from 1 session.
    insert into tst_lfs ( id, par_id, payload ) 
      select rownum, n_sid, 
             'r:' || to_char ( rownum ) || 'par_id: ' 
             || to_char ( n_sid ) || 'sysdate: ' || to_char ( sysdate, 'YYYY-MON-DD HH24:MI:SS' )
      from dual 
      where n_sid not in ( select par_id from tst_lfs )
      connect by level <= n_records ;

    -- n_stat_commits and n_ev_nrlfs , at start of test
    select value 
    into n_stat_commits 
    from v$mystat ms, v$statname sn
    where ms.statistic# = sn.statistic#
      and sn.name = 'user commits'; 

    select total_waits 
    into n_ev_nrlfs from  v$system_event
    where event like 'log file sync' ;

	starttime := sysdate ;

	while (sysdate - starttime) * 24 * 2600 <  n_secs  loop

        -- get a working nr for this loop-run
        n_recid := round ( dbms_random.value ( 1, n_records ) );

        -- delete a records, known id.
        delete from tst_lfs where id = n_recid and par_id = n_sid ;      

        commit  ;

        -- update a random record, some other record
        update tst_lfs 
            set payload  = payload || 'upd at cntr: ' || to_char ( n_counter )
            where id     = mod ( n_recid + n_counter , n_records ) + 1  
              and par_id = n_sid ;      
        
        commit  ;

        insert into tst_lfs 
            values ( n_recid, n_sid
               , 'Fresh Insert @ cntr: ' || to_char ( n_counter ) 
            || ' at tmstmp: ' || to_char ( sysdate, 'YYYY-MON-DD HH24:MI:SS' ) ) ; 

        commit  ;
/**
		insert into mytimer values ( sysdate ) ;
		insert into def select * from abc ;
		insert into def select * from abc ;
		delete from mytimer ;
		delete from def ;
***/

        n_counter := n_counter + 1; 
        
        -- optinal: an ERROR-catch here..

	end loop ;

    -- deltas for n_stat_commits and n_ev_nrlfs , at end of test
    select                  value  - n_stat_commits
    into n_stat_commits 
    from v$mystat ms, v$statname sn
    where ms.statistic# = sn.statistic#
      and sn.name = 'user commits'; 

    select                  total_waits  - n_ev_nrlfs
    into n_ev_nrlfs from  v$system_event
    where event like 'log file sync' ;

    -- report
    dbms_output.put_line ( 'spin_commit:            sid: ' 
                            || n_sid  || ' (= my sid)' ) ;
    dbms_output.put_line ( 'spin_commit:     loops done: ' 
                            || n_counter ) ;
    dbms_output.put_line ( 'spin_commit:    usr_commits: ' 
                            || to_char ( n_stat_commits, '9,999,999' ) || ', '  
                            || to_char ( round ( n_stat_commits / n_secs, 1 ) ) || ' cmts/sec' );
    dbms_output.put_line ( 'spin_commit: log-file-syncs: ' 
                            || to_char ( n_ev_nrlfs,     '9,999,999' ) || ', ' 
                            || to_char ( round ( n_ev_nrlfs      / n_secs, 1) ) || ' lfs/sec' 
                            || ' (=system wide)' ); 
   
end ;
/

-- select to_char ( sysdate, 'HH24:MI:SS' ) from dual;

--@sleep &1

--select to_char ( sysdate, 'HH24:MI:SS' ) from dual;

