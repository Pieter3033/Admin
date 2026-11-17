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

-- Creation stores Name + ' ' + Surname in CC_operators for CC (8) and Reload (14).
-- Capture that identity before deleting the account; never use a submitted name.
SET delete_user_existed = (
    SELECT CASE WHEN EXISTS (SELECT 1 FROM User_Info WHERE Username = :del_username)
                THEN 1 ELSE 0 END
);
SET delete_cc_operator_name = (
    SELECT TOP (1) Name + N' ' + Surname
    FROM User_Info
    WHERE Username = :del_username AND TRY_CONVERT(int, Usertype) IN (8, 14)
);

DELETE FROM User_Info WHERE Username = :del_username;

-- Verify that an existing account is gone before deleting its operator entries.
SET delete_user_deleted = CASE WHEN TRY_CONVERT(int, $delete_user_existed) = 1
                                   AND NOT EXISTS (SELECT 1 FROM User_Info WHERE Username = :del_username)
                              THEN 1 ELSE 0 END;

-- Remove matching operator entries only after a CC account has been deleted.
-- CC_operators has no username link, so retain a name another CC account still uses.
DELETE FROM [ExampleOperationsDb].[dbo].[CC_operators]
WHERE TRY_CONVERT(int, $delete_user_deleted) = 1
  AND [operator] COLLATE DATABASE_DEFAULT = $delete_cc_operator_name
  AND NOT EXISTS (
      SELECT 1 FROM User_Info remaining_user
      WHERE TRY_CONVERT(int, remaining_user.Usertype) IN (8, 14)
        AND remaining_user.Name + N' ' + remaining_user.Surname = $delete_cc_operator_name
  );

-- Report success after cleanup, including when a shared operator name is retained.
SET delete_cc_operator_shared = (
    SELECT CASE WHEN EXISTS (
        SELECT 1 FROM User_Info remaining_user
        WHERE TRY_CONVERT(int, remaining_user.Usertype) IN (8, 14)
          AND remaining_user.Name + N' ' + remaining_user.Surname = $delete_cc_operator_name
    ) THEN 1 ELSE 0 END
);
SET delete_cc_cleanup_complete = (
    SELECT CASE WHEN TRY_CONVERT(int, $delete_cc_operator_shared) = 1
                     OR NOT EXISTS (
                         SELECT 1 FROM [ExampleOperationsDb].[dbo].[CC_operators]
                         WHERE [operator] COLLATE DATABASE_DEFAULT = $delete_cc_operator_name
                     )
                THEN 1 ELSE 0 END
);

SELECT 'datagrid_transparent' AS component,
       CASE WHEN TRY_CONVERT(int, $delete_user_deleted) = 1
                  AND TRY_CONVERT(int, $delete_cc_cleanup_complete) = 1
            THEN 'Delete User Success!' ELSE 'Delete User Failed!' END AS title;

SELECT 'Status' AS title,
       CASE WHEN TRY_CONVERT(int, $delete_user_deleted) = 1
                  AND TRY_CONVERT(int, $delete_cc_cleanup_complete) = 1
            THEN 'Success' ELSE 'Failed' END AS description,
       CASE WHEN TRY_CONVERT(int, $delete_user_deleted) = 1
                  AND TRY_CONVERT(int, $delete_cc_cleanup_complete) = 1
            THEN 'check' ELSE 'x' END AS icon,
       CASE WHEN TRY_CONVERT(int, $delete_user_deleted) = 1
                  AND TRY_CONVERT(int, $delete_cc_cleanup_complete) = 1
            THEN 'green' ELSE 'red' END AS color;

SELECT 'Description' AS title,
       CASE WHEN COALESCE(TRY_CONVERT(int, $delete_user_deleted), 0) <> 1
            THEN 'Username does not exist'
            WHEN COALESCE(TRY_CONVERT(int, $delete_cc_cleanup_complete), 0) <> 1
            THEN 'User deleted, but CC operator cleanup failed'
            WHEN TRY_CONVERT(int, $delete_cc_operator_shared) = 1
            THEN 'User deleted. The operator name is still used by another CC account'
            WHEN $delete_cc_operator_name IS NOT NULL
            THEN 'User and matching CC operator entries deleted'
            ELSE 'User has been deleted' END AS description;

--------------------------------------------------------

SELECT 'button_Edited' AS component
SELECT 'check' AS icon
      ,'delete_user.sql?tab=Delete%20User' AS link
      ,'blue' AS color
      ,'Return' AS title

