-- 全国税务机构代码和名称
select swjg_dm,swjgmc,swjgjc,yxbz,xybz from hx_dm_zdy.dm_gy_swjg 
where swjg_dm='111010179167'
 order by swjg_dm
/*
1 机构层级：上一级机构代码尾数是0000或00000 不是000000不是0000000不是00000000不是

00000000000的为县局、
尾数是000000  不是0000000不是00000000不是00000000000的为市局、
尾数是00000000或00000000000的为省局
-- 计划单列市如何计划 不区分，人工判断


2 同一上级机构代码的机构名称个数  同一机构名称中的功能代码数量  


3 需要分将原表区分为36个文档，每个文档两个sheet页，工作量不小今天不一定可以完成
-- 明细的统计区分文档，原有的明细文档在原有的上面进行新增

select distinct jgjc_dm from hx_dm_zdy.dm_gy_swjg order by jgjc_dm
select * from hx_dm_qg.dm_gy_jgjc;


-- 同一上级机构代码的机构名称个数  同一机构名称中的功能代码数量 ,第二次电话要求增加机构配置的人员数量 
--表格2 这个上级机构个数思路有问题是指汇总表的个数
select decode(substr(swjg.jgjc_dm,1,1),'0','总局','1','省级','2','副省级或计划单列市','3','市级','4','区县级','5','乡镇级','6','股级',swjg.jgjc_dm) jgjc,
sjswjg.swjg_dm as sjjgdm,sjswjg.swjgmc as sjjgmc,count(sjswjg.swjg_dm) sjjgs,
rymx.sfswjg_dm,rymx.swjgmc,count(distinct rymx.gn_dm) gns,count(distinct rymx.swry_dm) rs
from ypt_sj_pzqk_arytj_mx rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '111%'  -- and rymx.sfswjg_dm not like '14403%'  -- 用来分省局导出
group by swjg.jgjc_dm,sjswjg.swjg_dm,sjswjg.swjgmc,rymx.sfswjg_dm,rymx.swjgmc
*/
-- 明细数据增加机构层级，上级机构代码，上级机构名称 --表格1

select decode(substr(swjg.jgjc_dm,1,1),'0','总局','1','省级','2','副省级或计划单列市','3','市级','4','区县级','5','乡镇级','6','股级',swjg.jgjc_dm) jgjc,
sjswjg.swjg_dm as sjjgdm,sjswjg.swjgmc as sjjgmc,rymx.*
from ypt_sj_pzqk_arytj_mx rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '165%'  -- and rymx.sfswjg_dm not like '14403%'  -- 用来分省局导出

--同一上级机构代码的机构名称个数  同一机构名称中的功能代码数量 ,第二次电话要求增加机构配置的人员数量 
--表格2 这个上级机构个数应该是汇总表的上级机构个数
select decode(substr(swjg.jgjc_dm,1,1),'0','总局','1','省级','2','副省级或计划单列市','3','市级','4','区县级','5','乡镇级','6','股级',swjg.jgjc_dm) jgjc,
sjswjg.swjg_dm as sjjgdm,sjswjg.swjgmc as sjjgmc,
count(1) over (partition by sjswjg.swjg_dm) sjjggs,
rymx.sfswjg_dm,rymx.swjgmc,count(distinct rymx.gn_dm) gns,count(distinct rymx.swry_dm) rs
from ypt_sj_pzqk_arytj_mx rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '111%'  -- and rymx.sfswjg_dm not like '14403%'  -- 用来分省局导出
group by swjg.jgjc_dm,sjswjg.swjg_dm,sjswjg.swjgmc,rymx.sfswjg_dm,rymx.swjgmc

-- 验证
select * from ypt_sj_pzqk_arytj_mx mx where mx.sfswjg_dm='16104000100'


