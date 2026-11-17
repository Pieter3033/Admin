-- Resolve the administrator from the session, never from the username cookie.
SELECT 'redirect' AS component, '/signin.sql?error' AS link
WHERE NOT EXISTS (
    SELECT 1 FROM Current_session s JOIN User_info u ON u.Username = s.Username
    WHERE s.session_id = sqlpage.cookie('session_admin') AND u.Usertype = 0
);
SET selected_user_id = (
    SELECT u.Seqno FROM User_info u
    WHERE u.Seqno = TRY_CONVERT(int, $user_id) AND u.Username <> 'TBC'
);
SET user_type_csrf = CASE WHEN LEN(sqlpage.cookie('admin_user_type_csrf')) = 48
                         THEN sqlpage.cookie('admin_user_type_csrf') ELSE sqlpage.random_string(48) END;
SELECT 'cookie' AS component, 'admin_user_type_csrf' AS name, $user_type_csrf AS value,
       '/Admin' AS path, 1 AS http_only, 'strict' AS same_site,
       CASE WHEN sqlpage.protocol() = 'https' THEN 1 ELSE 0 END AS secure;
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
       '/Admin/admin.css?v=20261023-1' AS css,
       '/Admin/admin.js?v=20261023-1' AS javascript,
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
SELECT 'html' AS component, '<section class="admin-hero"><div><p class="admin-eyebrow">Pulsit workspace / Administration</p><h2>Manage your workspace.</h2><p>People, permissions and access, all in one place.</p></div><div class="admin-hero-mark"><svg class="admin-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3 3 7v5c0 5 9 9 9 9s9-4 9-9V7zM8 12l3 3 5-6"/></svg></div></section>' AS html;
-- Summary figures are read-only and use the same directory filter.
SELECT 'html' AS component,
       '<section class="admin-stats" aria-label="User overview"><div class="admin-stat"><div><span class="admin-stat-label">Total users</span><strong class="admin-stat-value">'
       + CONVERT(varchar(20), COUNT(*))
       + '</strong></div><span class="admin-stat-icon"><svg class="admin-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M16 3a4 4 0 0 1 0 8M22 21v-2a4 4 0 0 0-3-3.87"/><circle cx="9" cy="7" r="4"/></svg></span></div><div class="admin-stat"><div><span class="admin-stat-label">Administrators</span><strong class="admin-stat-value">'
       + CONVERT(varchar(20), COALESCE(SUM(CASE WHEN Usertype = 0 THEN 1 ELSE 0 END), 0))
       + '</strong></div><span class="admin-stat-icon"><svg class="admin-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3 3 7v5c0 5 9 9 9 9s9-4 9-9V7zM8 12l3 3 5-6"/></svg></span></div><div class="admin-stat"><div><span class="admin-stat-label">User types in use</span><strong class="admin-stat-value">'
       + CONVERT(varchar(20), COUNT(DISTINCT CASE WHEN Usertype = 1 AND COALESCE(Helpdesk, 0) = 1 THEN 'helpdesk' ELSE CONVERT(varchar(20), Usertype) END))
       + '</strong></div><span class="admin-stat-icon"><svg class="admin-icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="8" cy="15" r="5"/><path d="m11.5 11.5 8-8M16 7l3 3M18 5l3 3"/></svg></span></div></section>' AS html
FROM User_info WHERE Username <> 'TBC';
SELECT 'html' AS component, '<div class="admin-workspace"><section class="admin-editor" aria-labelledby="admin-editor-title"><div class="admin-panel-header"><h3 id="admin-editor-title"><svg class="admin-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3 3 7v5c0 5 9 9 9 9s9-4 9-9V7zM8 12l3 3 5-6"/></svg>Update user type</h3><p>Choose a user and update their workspace access.</p></div><nav class="admin-tabs" aria-label="User management"><a href="admin.sql">Add user</a><a href="update_user_type.sql" aria-current="page">Update user type</a><a href="reset_password.sql">Reset password</a><a href="delete_user.sql?tab=Delete%20User" class="admin-tab-danger">Delete user</a></nav>' AS html;
SELECT 'form_new' AS component, 'get' AS method, 'update_user_type.sql' AS action,
       'Load user' AS validate, 'blue' AS validate_color, 'admin-user-picker' AS id;
SELECT 'user_id' AS name, 'User' AS label, 'select' AS type, 'TRUE' AS required,
       CONVERT(nvarchar(20), $selected_user_id) AS value,
       (SELECT choice.label, choice.value FROM (
           SELECT N'Select a user' AS label, N'' AS value, 0 AS sort_order
           UNION ALL
           SELECT u.Username, CONVERT(nvarchar(20), u.Seqno), 1
           FROM User_info u WHERE u.Username <> 'TBC'
       ) choice ORDER BY choice.sort_order, choice.label FOR JSON PATH) AS options;
SELECT 'alert' AS component, 'User unavailable' AS title, 'yellow' AS color,
       'Choose an existing user from the directory.' AS description
WHERE NULLIF($user_id, '') IS NOT NULL AND $selected_user_id IS NULL;
SELECT 'form_new' AS component, 'update_user_type_func.sql' AS action,
       'Save user type' AS validate, 'blue' AS validate_color, 'admin-user-type-form' AS id,
       (SELECT N'Access for ' + u.Username FROM User_info u WHERE u.Seqno = $selected_user_id) AS title
WHERE $selected_user_id IS NOT NULL;
SELECT 'target_id' AS name, 'hidden' AS type, CONVERT(varchar(20), $selected_user_id) AS value
WHERE $selected_user_id IS NOT NULL;
SELECT 'expected_type' AS name, 'hidden' AS type, CONVERT(varchar(20), u.Usertype) AS value
FROM User_info u WHERE u.Seqno = $selected_user_id;
SELECT 'expected_team' AS name, 'hidden' AS type, COALESCE(u.DispatchTeamCode, '') AS value
FROM User_info u WHERE u.Seqno = $selected_user_id;
SELECT 'expected_helpdesk' AS name, 'hidden' AS type, CONVERT(varchar(20), COALESCE(u.Helpdesk, 0)) AS value
FROM User_info u WHERE u.Seqno = $selected_user_id;
SELECT 'csrf_token' AS name, 'hidden' AS type, $user_type_csrf AS value
WHERE $selected_user_id IS NOT NULL;
SELECT 'user_type' AS name, 'New user type' AS label, 'select' AS type, 'TRUE' AS required,
       CASE WHEN u.Usertype = 1 AND COALESCE(u.Helpdesk, 0) = 1 THEN 'helpdesk'
            ELSE CONVERT(varchar(20), u.Usertype) END AS value,
       'Helpdesk includes ticket management, SRF jobcards and ODO checks. Completed Dispatch Viewer can only view completed dispatches and download their reports.' AS description,
       '[{"label":"Select a user type","value":""},{"label":"Admin","value":"0"},{"label":"SRF","value":"1"},{"label":"Helpdesk","value":"helpdesk"},{"label":"Technician","value":"2"},{"label":"Inspections Tester","value":"3"},{"label":"Impala Locks","value":"4"},{"label":"DSV Temperature","value":"5"},{"label":"Reload Checklists","value":"6"},{"label":"CC Admin","value":"7"},{"label":"CC","value":"8"},{"label":"Ground Team","value":"11"},{"label":"IBLS","value":"12"},{"label":"CRM","value":"13"},{"label":"Reload","value":"14"},{"label":"Completed Dispatch Viewer","value":"15"}]' AS options, 12 AS width
FROM User_info u WHERE u.Seqno = $selected_user_id;
SELECT 'dispatch_team_code' AS name,
       'Ground team' AS label,
       'select' AS type,
       (
           SELECT team_option.label, team_option.value
           FROM (
               SELECT N'Select a ground team' AS label, N'' AS value,
                      0 AS option_group, 0 AS display_order
               UNION ALL
               SELECT TeamName + N' (' + TeamCode + N')', TeamCode,
                      1, DisplayOrder
               FROM CC.dbo.DispatchTeams
               WHERE IsActive = 1
           ) team_option
           ORDER BY team_option.option_group, team_option.display_order, team_option.label
           FOR JSON PATH
       ) AS options,
       'Required for Ground Team profiles. Choose the team this person represents.' AS description,
       12 AS width,
       (SELECT DispatchTeamCode FROM User_info WHERE Seqno = $selected_user_id) AS value
WHERE $selected_user_id IS NOT NULL;

SELECT 'html' AS component, '<p class="admin-form-note">After saving, the user must sign in again to use their updated access.</p></section><section class="admin-directory" aria-labelledby="admin-directory-title"><div class="admin-panel-header"><h3 id="admin-directory-title">User directory</h3><p>Select Update type beside a user to edit their access.</p></div>' AS html;
SELECT 'table' AS component, 'TRUE' AS search, 'TRUE' AS sort,
       'No users found.' AS empty_description, 'Access' AS markdown;
SELECT Username, Name, Surname, Email,
       '[Update type](/Admin/update_user_type.sql?user_id=' + CONVERT(varchar(20), Seqno) + ')' AS Access,
       CASE WHEN Usertype = 0 THEN 'Admin'
            WHEN Usertype = 1 AND COALESCE(Helpdesk, 0) = 1 THEN 'Helpdesk'
            WHEN Usertype = 1 THEN 'SRF'
            WHEN Usertype = 2 THEN 'Technician'
            WHEN Usertype = 3 THEN 'Inspection Tester'
            WHEN Usertype = 4 THEN 'Impala Locks'
            WHEN Usertype = 5 THEN 'DSV Temperature Monitor'
            WHEN Usertype = 6 THEN 'Reload Checklists'
            WHEN Usertype = 7 THEN 'CC Admin'
            WHEN Usertype = 8 THEN 'CC'
            WHEN Usertype = 11 THEN 'Ground Team'
            WHEN Usertype = 12 THEN 'IBLS'
            WHEN Usertype = 13 THEN 'CRM'
            WHEN Usertype = 14 THEN 'Reload'
            WHEN Usertype = 15 THEN 'Completed Dispatch Viewer'
            ELSE 'Other' END AS "User Type",
       CASE WHEN Usertype = 11
            THEN COALESCE(NULLIF(DispatchTeamCode, ''), 'Unassigned') END AS "Ground Team"
FROM User_info WHERE Username <> 'TBC';
SELECT 'html' AS component, '<p class="admin-directory-footer">Select Update type to edit access. Column headings sort the directory.</p></section></div>' AS html;
