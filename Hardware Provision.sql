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
       '{"title":"Inspect unit","link":"/Admin/Inspect%20Unit.sql","icon":"scan"}' AS menu_item,
       '{"title":"Sign out","link":"/Admin/Logout.sql","icon":"logout"}' AS menu_item;
SELECT 'html' AS component, '<section class="admin-hero"><div><p class="admin-eyebrow">Pulsit workspace / Administration</p><h2>Hardware provision.</h2><p>Keep track of the equipment assigned to your team.</p></div><div class="admin-hero-mark"><svg class="admin-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="m12 3 9 5v8l-9 5-9-5V8zM3 8l9 5 9-5M12 13v8M7.5 5.5l9 5"/></svg></div></section>' AS html;
SELECT 'html' AS component, '<div class="admin-toolbar"><p>Equipment allocation and provision records</p><a class="btn btn-blue" href="add.sql">+ Add equipment</a></div><section class="admin-section" aria-label="Hardware records">' AS html;
SELECT 'table' AS component, 'TRUE' AS search, 'TRUE' AS sort, 'No equipment records found.' AS empty_description;
SELECT
      Employee AS Employee
      ,Provided_date AS "Date Provided"
      ,Item AS Item
      ,Make AS "Make/Model"
      ,Serial_num AS "Serial Number"
FROM ExampleHardwareDb.dbo.Hardware_Provision;
SELECT 'html' AS component, '</section>' AS html;
