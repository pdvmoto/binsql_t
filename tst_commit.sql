
CREATE TABLE commit_test (
  id           NUMBER(10),
  description  VARCHAR2(50),
  CONSTRAINT commit_test_pk PRIMARY KEY (id)
);

SET SERVEROUTPUT ON
DECLARE
  PROCEDURE do_loop (p_type  IN  VARCHAR2) AS
    l_start  NUMBER;
    l_loops  NUMBER := 500;
  BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE commit_test';

/** when using session-level parameter 

      CASE p_type
        WHEN 'WAIT'             THEN execute immediate ( 'alter session set commit_write = WAIT'); 
        WHEN 'NOWAIT'           THEN execute immediate ( 'alter session set commit_write = NOWAIT'); 
        WHEN 'BATCH'            THEN execute immediate ( 'alter session set commit_write = BATCH'); 
        WHEN 'IMMEDIATE'        THEN execute immediate ( 'alter session set commit_write = IMMEDIATE'); 
        WHEN 'BATCH,WAIT'       THEN execute immediate ( 'alter session set commit_write = IMMEDIATE'); 
        WHEN 'BATCH,WAIT'       THEN COMMIT WRITE BATCH WAIT;
        WHEN 'BATCH,NOWAIT'     THEN COMMIT WRITE BATCH NOWAIT;
        WHEN 'IMMEDIATE,WAIT'   THEN COMMIT WRITE IMMEDIATE WAIT;
        WHEN 'IMMEDIATE,NOWAIT' THEN COMMIT WRITE IMMEDIATE NOWAIT;
        ELSE                          NULL ;
      END CASE;
***/

    l_start := DBMS_UTILITY.get_time;
    FOR i IN 1 .. l_loops LOOP
      INSERT INTO commit_test (id, description)
      VALUES (i, 'Description for ' || i);
      
      CASE p_type
        WHEN 'WAIT'             THEN COMMIT WRITE WAIT;
        WHEN 'NOWAIT'           THEN COMMIT WRITE NOWAIT;
        WHEN 'BATCH'            THEN COMMIT WRITE BATCH;
        WHEN 'IMMEDIATE'        THEN COMMIT WRITE IMMEDIATE;
        WHEN 'BATCH,WAIT'       THEN COMMIT WRITE BATCH WAIT;
        WHEN 'BATCH,NOWAIT'     THEN COMMIT WRITE BATCH NOWAIT;
        WHEN 'IMMEDIATE,WAIT'   THEN COMMIT WRITE IMMEDIATE WAIT;
        WHEN 'IMMEDIATE,NOWAIT' THEN COMMIT WRITE IMMEDIATE NOWAIT;
        ELSE                         commit ;
      END CASE;

    END LOOP;
    DBMS_OUTPUT.put_line(RPAD('COMMIT WRITE ' || p_type, 30) || ': ' || (DBMS_UTILITY.get_time - l_start));
  END;
BEGIN
  do_loop('IMMEDIATE,NOWAIT');
  do_loop('IMMEDIATE,WAIT');
  do_loop('BATCH,NOWAIT');
  do_loop('BATCH,WAIT');
  do_loop('IMMEDIATE');
  do_loop('NOWAIT');
  do_loop('WAIT');
  -- do_loop('default');
  do_loop('WAIT');
  do_loop('NOWAIT');
  do_loop('BATCH');
  do_loop('IMMEDIATE');
  do_loop('BATCH,WAIT');
  do_loop('BATCH,NOWAIT');
  do_loop('IMMEDIATE,WAIT');
  do_loop('IMMEDIATE,NOWAIT');
END;
/

