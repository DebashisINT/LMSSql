IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Proc_User_StateMAP]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [Proc_User_StateMAP] AS' 
END
GO


--exec Proc_User_StateMAP 'EMP0000002'


ALTER Proc [dbo].[Proc_User_StateMAP]

@EMPID varchar(100)
As

Begin

declare  @UserId bigint
set @UserId=(select  isnull(user_id,'')  from tbl_master_user where user_contactId=@EMPID)

if(@UserId<>'')
BEGIN
IF EXISTS(select  [USER_ID]  from  FTS_EMPSTATEMAPPING where [USER_ID]=@UserId and State_ID=0 )
BEGIN
select *  from
(

select  'All' as StateName ,0 as StateID,cast(1 as bit) as IsChecked ,'Success' as status 

UNION ALL

select  state as StateName ,id as StateID,cast(1 as bit) as IsChecked ,'Success' as status from tbl_master_state as stat  
LEFT OUTER JOIN FTS_EMPSTATEMAPPING as empmapstate on stat.id=empmapstate.STATE_ID
and empmapstate.USER_ID=@UserId
)T
order by T.StateName



END
ELSE
BEGIN
select *  from
(

select  'All' as StateName ,0 as StateID,cast(0 as bit) as IsChecked ,'Success' as status 

UNION ALL
select  state as StateName ,id as StateID,case  when isnull(empmapstate.USER_ID,'')='' then cast(0 as bit) else cast(1 as bit) end as IsChecked,'Success' as status from tbl_master_state as stat  
LEFT OUTER JOIN FTS_EMPSTATEMAPPING as empmapstate on stat.id=empmapstate.STATE_ID
and empmapstate.USER_ID=@UserId
)T
order by T.StateName


END

END

ENd
GO
