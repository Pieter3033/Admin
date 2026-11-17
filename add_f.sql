INSERT INTO ExampleHardwareDb.dbo.Hardware_Provision ([Item]
      ,[Make]
      ,[Serial_num]
      ,[Employee]
      ,[Provided_date])
VALUES(
 :item
,:make_model
,:s_num
,:employee
,:p_date)

SELECT 'redirect' AS component
      ,'Hardware Provision.sql' AS link