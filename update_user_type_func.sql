-- Only a current administrator may submit this form.
SELECT 'redirect' AS component, '/signin.sql?error' AS link
WHERE NOT EXISTS (
    SELECT 1 FROM Current_session s JOIN User_info u ON u.Username = s.Username
    WHERE s.session_id = sqlpage.cookie('session_admin') AND u.Usertype = 0
);
SELECT 'redirect' AS component, 'update_user_type.sql' AS link
WHERE sqlpage.request_method() <> 'POST';

-- BEGIN ROLE VALIDATION: all values are resolved again on the server.
SET update_target_id = TRY_CONVERT(int, :target_id);
SET update_new_type = CASE WHEN LTRIM(RTRIM(:user_type)) = 'helpdesk' THEN 1
                           ELSE TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(:user_type)), '')) END;
SET update_expected_type = TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(:expected_type)), ''));
SET update_expected_helpdesk = TRY_CONVERT(int, NULLIF(LTRIM(RTRIM(:expected_helpdesk)), ''));
SET update_old_type = (SELECT u.Usertype FROM User_info u WHERE u.Seqno = $update_target_id AND u.Username <> 'TBC');
SET update_old_helpdesk = (SELECT COALESCE(u.Helpdesk, 0) FROM User_info u WHERE u.Seqno = $update_target_id AND u.Username <> 'TBC');
-- Keep an existing extra Helpdesk entitlement when the base profile is unchanged.
-- Choosing SRF explicitly removes Helpdesk; choosing Helpdesk enables it.
SET update_new_helpdesk = CASE WHEN LTRIM(RTRIM(:user_type)) = 'helpdesk' THEN 1
                               WHEN $update_new_type IN (1, 15) THEN 0
                               WHEN $update_new_type = $update_old_type THEN $update_old_helpdesk
                               ELSE 0 END;
SET update_old_team = (SELECT u.DispatchTeamCode FROM User_info u WHERE u.Seqno = $update_target_id AND u.Username <> 'TBC');
SET update_username = (SELECT u.Username FROM User_info u WHERE u.Seqno = $update_target_id AND u.Username <> 'TBC');
SET update_operator_name = (SELECT u.Name + N' ' + u.Surname FROM User_info u WHERE u.Seqno = $update_target_id AND u.Username <> 'TBC');
SET update_team_code = (
    SELECT TOP (1) t.TeamCode FROM CC.dbo.DispatchTeams t
    WHERE t.IsActive = 1 AND t.TeamCode = LTRIM(RTRIM(:dispatch_team_code))
      AND $update_new_type = 11
);
SET update_validation = CASE
    WHEN sqlpage.request_method() <> 'POST' THEN 'invalid_method'
    WHEN NOT EXISTS (
        SELECT 1 FROM Current_session s JOIN User_info u ON u.Username = s.Username
        WHERE s.session_id = sqlpage.cookie('session_admin') AND u.Usertype = 0
    ) THEN 'unauthorized'
    WHEN LEN(:csrf_token) <> 48 OR LEN(sqlpage.cookie('admin_user_type_csrf')) <> 48
      OR :csrf_token IS NULL OR sqlpage.cookie('admin_user_type_csrf') IS NULL
      OR CONVERT(varbinary(96), CONVERT(nvarchar(48), :csrf_token))
         <> CONVERT(varbinary(96), CONVERT(nvarchar(48), sqlpage.cookie('admin_user_type_csrf')))
        THEN 'invalid_form'
    WHEN $update_username IS NULL THEN 'not_found'
    WHEN (SELECT COUNT(*) FROM User_info u WHERE u.Username = $update_username) <> 1 THEN 'ambiguous_username'
    WHEN $update_new_type IS NULL OR $update_new_type NOT IN (0, 1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14, 15) THEN 'invalid_type'
    WHEN $update_expected_type IS NULL OR $update_old_type <> $update_expected_type
      OR $update_expected_helpdesk IS NULL OR $update_old_helpdesk <> $update_expected_helpdesk
      OR COALESCE($update_old_team, '') <> COALESCE(:expected_team, '') THEN 'stale_user'
    WHEN $update_new_type = 11 AND $update_team_code IS NULL THEN 'invalid_ground_team'
    WHEN $update_new_type IN (8, 14) AND NULLIF(LTRIM(RTRIM($update_operator_name)), '') IS NULL THEN 'missing_name'
    WHEN $update_old_type = 0 AND $update_new_type <> 0
      AND (SELECT COUNT(*) FROM User_info u WHERE u.Usertype = 0 AND u.Username <> 'TBC') <= 1 THEN 'last_admin'
    WHEN $update_old_type = $update_new_type
      AND $update_old_helpdesk = $update_new_helpdesk
      AND COALESCE($update_old_team, '') = COALESCE($update_team_code, '') THEN 'no_changes'
    ELSE 'ready'
END;
-- END ROLE VALIDATION

-- Recheck the loaded values and administrator count inside the update itself.
-- The lock on the administrator set prevents simultaneous last-admin demotions.
UPDATE User_info
SET Usertype = $update_new_type, Helpdesk = $update_new_helpdesk, DispatchTeamCode = $update_team_code
WHERE Seqno = $update_target_id AND Username = $update_username AND Username <> 'TBC'
  AND $update_validation = 'ready'
  AND Usertype = $update_expected_type
  AND COALESCE(Helpdesk, 0) = $update_expected_helpdesk
  AND COALESCE(DispatchTeamCode, '') = COALESCE(:expected_team, '')
  AND EXISTS (
      SELECT 1 FROM Current_session s JOIN User_info actor ON actor.Username = s.Username
      WHERE s.session_id = sqlpage.cookie('session_admin') AND actor.Usertype = 0
  )
  AND ($update_old_type <> 0 OR $update_new_type = 0 OR (
      SELECT COUNT(*) FROM User_info admins WITH (UPDLOCK, HOLDLOCK)
      WHERE admins.Usertype = 0 AND admins.Username <> 'TBC'
  ) > 1);

SET update_applied = CASE WHEN $update_validation = 'ready' AND EXISTS (
    SELECT 1 FROM User_info u WHERE u.Seqno = $update_target_id
      AND u.Usertype = $update_new_type
      AND COALESCE(u.Helpdesk, 0) = $update_new_helpdesk
      AND COALESCE(u.DispatchTeamCode, '') = COALESCE($update_team_code, '')
) THEN 1 ELSE 0 END;

-- Revoke old role-specific sessions before synchronizing related directories.
DELETE FROM Current_session
WHERE Username = $update_username AND TRY_CONVERT(int, $update_applied) = 1;

-- CC and Reload share the operator directory. Keep an existing operator ID.
INSERT INTO [ExampleOperationsDb].[dbo].[CC_operators] ([operator], [id])
SELECT $update_operator_name, COALESCE(MAX(o.[id]), 0) + 1
FROM [ExampleOperationsDb].[dbo].[CC_operators] o WITH (UPDLOCK, HOLDLOCK)
HAVING TRY_CONVERT(int, $update_applied) = 1 AND $update_new_type IN (8, 14)
   AND NOT EXISTS (
       SELECT 1 FROM [ExampleOperationsDb].[dbo].[CC_operators] existing
       WHERE existing.[operator] COLLATE DATABASE_DEFAULT = $update_operator_name
   );

-- Retain operator names that another CC or Reload account still uses.
DELETE FROM [ExampleOperationsDb].[dbo].[CC_operators]
WHERE TRY_CONVERT(int, $update_applied) = 1
  AND $update_old_type IN (8, 14) AND $update_new_type NOT IN (8, 14)
  AND [operator] COLLATE DATABASE_DEFAULT = $update_operator_name
  AND NOT EXISTS (
      SELECT 1 FROM User_info u
      WHERE u.Usertype IN (8, 14) AND u.Name + N' ' + u.Surname = $update_operator_name
  );

SET update_complete = CASE WHEN TRY_CONVERT(int, $update_applied) = 1
    AND NOT EXISTS (SELECT 1 FROM Current_session s WHERE s.Username = $update_username)
    AND ($update_new_type NOT IN (8, 14) OR EXISTS (
        SELECT 1 FROM [ExampleOperationsDb].[dbo].[CC_operators] o
        WHERE o.[operator] COLLATE DATABASE_DEFAULT = $update_operator_name
    ))
    AND ($update_old_type NOT IN (8, 14) OR $update_new_type IN (8, 14)
      OR EXISTS (SELECT 1 FROM User_info u WHERE u.Usertype IN (8, 14) AND u.Name + N' ' + u.Surname = $update_operator_name)
      OR NOT EXISTS (SELECT 1 FROM [ExampleOperationsDb].[dbo].[CC_operators] o WHERE o.[operator] COLLATE DATABASE_DEFAULT = $update_operator_name))
    THEN 1 ELSE 0 END;

SELECT 'shell' AS component, 'Admin portal' AS title, '/Admin/admin.sql' AS link,
       'fluid' AS layout, 'dark' AS theme, 'Inter:wght@400;500;600;700' AS font,
       '/Admin/logowhite_3.png' AS image, '/Admin/favicon.png' AS favicon,
       '/Admin/admin.css?v=20261023-1' AS css, '/Admin/admin.js?v=20261023-1' AS javascript,
       'admin-portal' AS class,
       '{"title":"Users","link":"/Admin/admin.sql","icon":"users"}' AS menu_item,
       '{"title":"Sign out","link":"/Admin/Logout.sql","icon":"logout"}' AS menu_item;
SELECT 'alert' AS component,
       CASE WHEN TRY_CONVERT(int, $update_complete) = 1 THEN 'User type updated'
            WHEN $update_validation = 'no_changes' THEN 'No changes needed'
            ELSE 'User type update not completed' END AS title,
       CASE WHEN TRY_CONVERT(int, $update_complete) = 1 THEN 'green'
            WHEN $update_validation = 'no_changes' THEN 'blue' ELSE 'yellow' END AS color,
       CASE WHEN TRY_CONVERT(int, $update_complete) = 1
            THEN 'Access has been updated. The user must sign in again.'
            WHEN TRY_CONVERT(int, $update_applied) = 1
            THEN 'The user type changed, but related access updates could not be verified. Check the directory before trying again.'
            WHEN $update_validation = 'no_changes' THEN 'This user already has the selected user type, Helpdesk access and ground-team allocation.'
            WHEN $update_validation = 'invalid_form' THEN 'This form is no longer valid. Reload the user and try again.'
            WHEN $update_validation = 'not_found' THEN 'This user is no longer available. Choose an existing user.'
            WHEN $update_validation = 'ambiguous_username' THEN 'This username is shared by multiple accounts. Resolve the duplicate before changing access.'
            WHEN $update_validation = 'invalid_type' THEN 'Select a supported user type.'
            WHEN $update_validation = 'invalid_ground_team' THEN 'Select an active ground team for this profile.'
            WHEN $update_validation = 'missing_name' THEN 'A first name and surname are required for the CC operator directory.'
            WHEN $update_validation = 'stale_user' THEN 'This user changed after the form was loaded. Reload the user before saving.'
            WHEN $update_validation = 'last_admin' THEN 'Keep at least one administrator account. Assign another administrator before changing this user.'
            ELSE 'The update could not be verified. Reload the user and check their current access.' END AS description;
SELECT 'button_Edited' AS component;
SELECT 'arrow-left' AS icon,
       CASE WHEN TRY_CONVERT(int, $update_applied) = 1
                  AND NOT EXISTS (SELECT 1 FROM Current_session s WHERE s.session_id = sqlpage.cookie('session_admin'))
            THEN '/signin.sql'
            ELSE 'update_user_type.sql?user_id=' + COALESCE(CONVERT(varchar(20), $update_target_id), '') END AS link,
       'blue' AS color,
       CASE WHEN TRY_CONVERT(int, $update_applied) = 1
                  AND NOT EXISTS (SELECT 1 FROM Current_session s WHERE s.session_id = sqlpage.cookie('session_admin'))
            THEN 'Sign in' ELSE 'Return to user' END AS title;
