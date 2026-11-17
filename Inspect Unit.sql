INSERT INTO Current_session_archive (Username)
VALUES(sqlpage.cookie('username')); --Archiving the session, in the table it plots the timestamp as well.

INSERT INTO Current_session (Username, session_id)
VALUES (sqlpage.cookie('username'), sqlpage.random_string(32));


SELECT 'cookie' AS component
       ,'session_inspect' AS name
       ,(SELECT TOP(1) session_id               
      FROM Current_session 
      WHERE Username = sqlpage.cookie('username') ORDER BY login_time DESC) 
      AS value; 

SELECT 'redirect' AS component
       ,'/Inspection_tester/Main Menu.sql?=' + 'admin' AS link

