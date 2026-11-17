-- Admin access is checked before rendering any page data.
SELECT 'redirect' AS component, '/signin.sql?error' AS link
WHERE (SELECT session_id FROM Current_session
       WHERE session_id = sqlpage.cookie('session_admin')) IS NULL;
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
SELECT 'html' AS component, '<div class="admin-workspace"><section class="admin-editor" aria-labelledby="admin-editor-title"><div class="admin-panel-header"><h3 id="admin-editor-title"><svg class="admin-icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="8" cy="15" r="5"/><path d="m11.5 11.5 8-8M16 7l3 3M18 5l3 3"/></svg>Reset a password</h3><p>Help a user regain access to their account.</p></div><nav class="admin-tabs" aria-label="User management"><a href="admin.sql">Add user</a><a href="update_user_type.sql">Update user type</a><a href="reset_password.sql" aria-current="page">Reset password</a><a href="delete_user.sql?tab=Delete%20User" class="admin-tab-danger">Delete user</a></nav><p class="admin-notice admin-notice-neutral">Choose a user from the directory or enter their username below.</p>' AS html;
SELECT 'form_new' AS component,
       'reset_password_func.sql' AS action,
       'Reset password' AS validate,
       'blue' AS validate_color,
       'admin-user-form' AS id;
SELECT 'pass_reset_username' AS name,
       'Username' AS label,
       'Enter an existing username' AS placeholder,
       'TRUE' AS required,
       12 AS width,
       'off' AS autocomplete;

SELECT 'reset_password' AS name,
       'New password' AS label,
       'password' AS type,
       'Enter a new password' AS placeholder,
       'TRUE' AS required,
       12 AS width,
       'new-password' AS autocomplete;
SELECT 'html' AS component, '<p class="admin-form-note"><svg class="admin-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3 3 7v5c0 5 9 9 9 9s9-4 9-9V7zM8 12l3 3 5-6"/></svg>Select a username in the directory to fill this form.</p></section><section class="admin-directory" aria-labelledby="admin-directory-title"><div class="admin-panel-header"><h3 id="admin-directory-title">User directory</h3><p>Find people and check their workspace access.</p></div>' AS html;
SELECT 'table' AS component, 'TRUE' AS search, 'TRUE' AS sort,
       'No users found.' AS empty_description;
SELECT Username, Name, Surname,
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
            ELSE 'Other' END AS "User Type",
       CASE WHEN Usertype = 11
            THEN COALESCE(NULLIF(DispatchTeamCode, ''), 'Unassigned') END AS "Ground Team"
FROM User_info WHERE Username <> 'TBC';
SELECT 'html' AS component, '<p class="admin-directory-footer">Select a username to fill the form. Column headings sort the directory.</p></section></div>' AS html;
