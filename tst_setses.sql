
@where

@date

spool tst_setses

alter session enable parallel query;

@do_count 

@date

alter session disable parallel query

@do_count

@date

@spool off
