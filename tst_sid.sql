
 -- use sid to identify a table + use it

column mysid new_value mysid

select sys_context ( 'USERENV', 'SID' ) as mysid from dual ; 

prompt my sid is &mysid


drop table t_mysid_&mysid ; 
create table t_mysid_&mysid as select * from all_tables ; 

@count t_mysid_&mysid 

