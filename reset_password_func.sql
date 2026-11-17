--------------------------------------------------------
/**
   Redirect component, if user is not logged in
   user is redirected to login page

   Checks that the current session_id(stored as cookie)
   exists in the database
**/
SELECT 'redirect' AS component,
       '\signin.sql?error' AS link
WHERE (SELECT session_id FROM Current_session WHERE session_id = sqlpage.cookie('session_admin')) IS NULL;

--------------------------------------------------------
/**Default Shell component**/
SELECT 'shell' AS component,
       'Admin portal' AS title,
       '/Admin/admin.sql' AS link,
       'fluid' AS layout,
       'dark' AS theme,
       'en-US' AS language,
       'Inter:wght@400;500;600;700' AS font,
       16 AS font_size,
       '/Admin/logowhite_3.png' AS image,
       '/Admin/favicon.png' AS favicon,
       '/Admin/admin.css?v=20261013-1' AS css,
       '/Admin/admin.js?v=20261013-1' AS javascript,
       'admin-portal' AS class,
       'Make it happen — perfectly.' AS footer,
       '{"title":"Users","link":"/Admin/admin.sql","icon":"users"}' AS menu_item,
       CASE WHEN sqlpage.cookie('username') NOT IN ('Maryna','Steven')
            THEN '{"title":"Reload checklist","link":"/Admin/Reload_checklist.sql","icon":"list-check"}' END AS menu_item,
       CASE WHEN sqlpage.cookie('username') NOT IN ('Maryna','Steven')
            THEN '{"title":"Hardware","link":"/Admin/Hardware%20Provision.sql","icon":"device-desktop"}' END AS menu_item,
       CASE WHEN sqlpage.cookie('username') IN ('Maryna','Steven')
            THEN '{"title":"SRF","link":"/Admin/srf.sql","icon":"clipboard-list"}' END AS menu_item,
       CASE WHEN sqlpage.cookie('username') = 'admin'
            THEN '{"title":"Jobs","link":"/Admin/Jobs.sql","icon":"briefcase"}' END AS menu_item,
       
       '{"title":"Sign out","link":"/Admin/Logout.sql","icon":"logout"}' AS menu_item;

--------------------------------------------------------

SELECT 'datagrid_transparent' AS component
      ,(CASE WHEN :pass_reset_username =(SELECT TOP (1) Username FROM User_Info WHERE Username = :pass_reset_username) THEN 'Reset Password Success!'
        ELSE 'Reset Password Failed!' END) AS title;

SELECT 'Status' AS title
      ,(CASE WHEN :pass_reset_username =(SELECT TOP (1) Username FROM User_Info WHERE Username = :pass_reset_username) THEN 'Completed'
        ELSE 'Failed' END) AS description
      ,(CASE WHEN :pass_reset_username =(SELECT TOP (1) Username FROM User_Info WHERE Username = :pass_reset_username) THEN 'check'
        ELSE 'x' END) AS icon
      ,(CASE WHEN :pass_reset_username =(SELECT TOP (1) Username FROM User_Info WHERE Username = :pass_reset_username) THEN 'green'
        ELSE 'red' END) AS color;

SELECT 'Description' AS title
      ,(CASE WHEN :pass_reset_username =(SELECT TOP (1) Username FROM User_Info WHERE Username = :pass_reset_username) THEN 'Password reset successfully'
        ELSE 'Username does not exists' END) AS description

--------------------------------------------------------

UPDATE User_Info
SET hash_password = sqlpage.hash_password(:reset_password)
WHERE Username = :pass_reset_username;

--------------------------------------------------------

SELECT 'button_Edited' AS component
SELECT
       'check' AS icon
      ,'reset_password.sql' AS link
      ,'blue' AS color
      ,'Return' AS title