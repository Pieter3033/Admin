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
       
       '{"title":"Sign out","link":"/Admin/Logout.sql","icon":"logout"}' AS menu_item,
       10 AS refresh;
SELECT 'html' AS component, '<section class="admin-hero"><div><p class="admin-eyebrow">Pulsit workspace / Administration</p><h2>Job setup checks.</h2><p>Review jobs flagged with vehicle or unit setup issues.</p></div><div class="admin-hero-mark"><svg class="admin-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M9 5h10v16H5V5h4M9 3h6v4H9zM9 12l1 1 2-2M14 12h2M9 17l1 1 2-2M14 17h2"/></svg></div></section>' AS html;
SELECT 'html' AS component, '<div class="admin-toolbar"><p>Setup issues requiring attention</p><p>Refreshes every 10 seconds</p></div><section class="admin-section" aria-label="Job setup issues">' AS html;
SELECT 'table' AS component, 'TRUE' AS search, 'TRUE' AS sort, 'No setup issues found.' AS empty_description;
SELECT       [jc_num]
      ,[unit_id]
      ,[reg_no]
      ,[company]
      ,[fleet]
      ,[VehicleInfoExists]
      ,[UnitInfoExists_SameRegAndUnitId]
      ,[UnitInfoExists_AnyForRegNo]
      ,[setup_issue_detected]
      ,[BIS_VehicleInfoExists]
      ,[BIS_UnitInfoExists_SameRegAndUnitId]
      ,[BIS_UnitInfoExists_AnyForRegNo]
      ,[BIS_setup_issue_detected]
      ,[date_checked]
FROM jobcard_extra.dbo.setup_checker
WHERE setup_issue_detected = 1 or BIS_setup_issue_detected = 1;
SELECT 'html' AS component, '</section>' AS html;
