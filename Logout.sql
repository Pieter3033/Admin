--------------------------------------------------------
/**
Delete from session table when logout is pressed.
**/
DELETE FROM Current_session WHERE session_id = sqlpage.cookie('session');
DELETE FROM Current_session WHERE session_id = sqlpage.cookie('session_admin');

--------------------------------------------------------
/**
Clear the cookie values
**/
SELECT 'cookie' AS component, 'session' AS name, TRUE AS remove;
SELECT 'cookie' AS component, 'session_admin' AS name, TRUE AS remove;

--------------------------------------------------------
/**
Redirect to the signin page
**/
SELECT 'redirect' AS component, '/logout.sql' AS link;

--------------------------------------------------------