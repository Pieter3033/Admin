SELECT 'redirect' AS component,
       '/signin.sql?error' AS link
WHERE NOT EXISTS (
    SELECT 1 FROM Current_session s JOIN User_info u ON u.Username = s.Username
    WHERE s.session_id = sqlpage.cookie('session_admin') AND u.Usertype = 0
);

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
       '/Admin/admin.js?v=20261022-1' AS javascript,
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

SET add_user_existed = CASE WHEN EXISTS (SELECT 1 FROM User_Info WHERE Username = :add_username) THEN 1 ELSE 0 END;
SET add_user_password_hash = sqlpage.hash_password(:add_password);
-- Helpdesk is the existing SRF profile with its Helpdesk entitlement enabled.
SET add_user_type = CASE WHEN LTRIM(RTRIM(:user_type)) = 'helpdesk' THEN 1
                         ELSE TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(:user_type)), '')) END;
SET add_user_helpdesk = CASE WHEN LTRIM(RTRIM(:user_type)) = 'helpdesk' THEN 1 ELSE 0 END;

-- Resolve the canonical allocation from active teams; other roles have no allocation.
SET add_user_team_code = (
 SELECT TOP (1) TeamCode
 FROM CC.dbo.DispatchTeams
 WHERE IsActive = 1
   AND TeamCode = LTRIM(RTRIM(:dispatch_team_code))
   AND $add_user_type = 11
);

INSERT INTO User_Info (Name, Surname, Username, hash_password, Usertype, Email, DispatchTeamCode, Helpdesk)
SELECT :name, :surname, :add_username, $add_user_password_hash, $add_user_type,
       NULLIF(LOWER(LTRIM(RTRIM(:email))), ''), $add_user_team_code, $add_user_helpdesk
WHERE $add_user_existed = 0
  AND $add_user_type IN (0, 1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15)
  AND ($add_user_type <> 11 OR $add_user_team_code IS NOT NULL)
  AND EXISTS (
      SELECT 1 FROM Current_session s JOIN User_info actor ON actor.Username = s.Username
      WHERE s.session_id = sqlpage.cookie('session_admin') AND actor.Usertype = 0
  )
  AND NOT EXISTS (SELECT 1 Username
                  FROM User_Info
                  WHERE Username = :add_username);

-- Verify this request's salted password hash; an existing username cannot create a CC operator.
SET add_user_created = CASE WHEN $add_user_existed = 0 AND EXISTS (
 SELECT 1 FROM User_Info WHERE Username = :add_username
 AND CONVERT(VARBINARY(8000), CAST(hash_password AS NVARCHAR(4000)))
     = CONVERT(VARBINARY(8000), CAST($add_user_password_hash AS NVARCHAR(4000)))
) THEN 1 ELSE 0 END;

SET add_user_result = CASE
 WHEN $add_user_created = 1 THEN 'created'
 WHEN $add_user_existed = 1 THEN 'duplicate_username'
 WHEN $add_user_type IS NULL OR $add_user_type NOT IN (0, 1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15) THEN 'invalid_type'
 WHEN $add_user_type = 11 AND $add_user_team_code IS NULL THEN 'invalid_ground_team'
 ELSE 'creation_not_verified'
END;

-- CC (8) and Reload (14) share the operator directory. Allocate its operator ID within this locked insert statement.
INSERT INTO [ExampleOperationsDb].[dbo].[CC_operators] ([operator], [id])
SELECT :name + ' ' + :surname, COALESCE(MAX([id]), 0) + 1
FROM [ExampleOperationsDb].[dbo].[CC_operators] WITH (UPDLOCK, HOLDLOCK)
HAVING TRY_CONVERT(int, :user_type) IN (8, 14)
   AND TRY_CONVERT(int, $add_user_created) = 1;

SELECT 'datagrid_transparent' AS component
      ,(CASE WHEN TRY_CONVERT(int, $add_user_created) = 1 THEN 'Add User Success!'
                                  ELSE 'Add User Failed!' END) AS title;

SELECT 'Status' AS title
      ,(CASE WHEN TRY_CONVERT(int, $add_user_created) = 1 THEN 'User created!'
                                  ELSE 'User not created!' END) AS description
      ,(CASE WHEN TRY_CONVERT(int, $add_user_created) = 1 THEN 'check'
                                  ELSE 'x' END) AS icon
      ,(CASE WHEN TRY_CONVERT(int, $add_user_created) = 1 THEN 'green'
                                  ELSE 'red' END) AS color;

SELECT 'Description' AS title
      ,(CASE $add_user_result
          WHEN 'created' THEN 'User successfully created'
          WHEN 'duplicate_username' THEN 'Username already exists. Use Reset password if this is the intended account.'
          WHEN 'invalid_type' THEN 'Select a supported user type. No account was created.'
          WHEN 'invalid_ground_team' THEN 'Select an active ground team for this profile. No account was created.'
          ELSE 'Account creation could not be verified. Check the user directory before trying again.'
        END) AS description;


SELECT 'button_Edited' AS component
SELECT
       'check' AS icon
      ,'admin.sql?tab=Add%20User' AS link
      ,'blue' AS color
      ,'Return' AS title;
