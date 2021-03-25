-------名称：平台热门应用访问量本月top5------
--创建：李鹏超 20191028
--模块：【云平台应用使用情况】
--联系人：局方陈友胜老师
--上游： hx_dm_zdy.dm_gy_swry  税务人员代码
--        税务人员身份代码表
--        登录账户信息表
--       税务机构代码
--          税务机关岗位对照表
--       机构岗位税务人员身份
--          权限系统功能
--        功能树
--        岗位
--         门户常用功能统计


-- 按照提供的一级功能菜单名称查询出指定功能名单人员配置情况
-- truncate table ypt_sj_pzqk_arytj1114;
-- create table ypt_sj_pzqk_arytj1114 as 
insert into ypt_sj_pzqk_arytj1114
select  
distinct c.dlzh_dm  -- 登陆账号代码
,a.swry_dm        -- 税务人员代码
,a.swryxm         -- 税务人员姓名
,a.sfzjhm         -- 身份证件号码
,b.swrysf_dm       -- 税务人员身份代码
,b.rysfmc         -- 税务人员身份名称
,b.sfswjg_dm       -- 身份所属税务机构代码
,d.swjgmc         -- 身份所属税务机构名称
,j.gn_dm          -- 功能代码
,j.gnmc           -- 功能名称 
from  hx_dm_zdy.dm_gy_swry a 
,hx_qx.dm_qx_swrysf b  
,hx_qx.qx_dlzhxx c 
,hx_dm_zdy.dm_gy_swjg d  
,hx_qx.qx_swjg_gw f
,hx_qx.qx_jggw_swrysf g
,hx_qx.qx_gw_xtgn h
,hx_dm_qg.dm_qx_gns j
where a.swry_Dm = b.swry_dm
and b.sfswjg_dm = d.swjg_dm
and a.swry_dm=c.swry_dm
and f.gwxh=g.gwxh
and g.swrysf_dm=b.swrysf_dm
and b.sfswjg_dm=f.swjg_dm
and f.gw_dm= h.gw_dm 
and h.xtgn_dm = j.xtgn_dm 
-- 过滤功能名单
and j.gn_dm in 
(select gn_dm from hx_bak.ls_wjwjj f where 
    f.YJGNMC LIKE '%上游发票风险传播分析%'
    or f.YJGNMC LIKE '%云平台访问监控统计%'
    or f.YJGNMC LIKE '%全国纳税人涉税风险名录%'
    or f.YJGNMC LIKE '%用户权限管理%'
    or f.YJGNMC LIKE '%纳税人关系分析%'
    or f.YJGNMC LIKE '%数据管控治理平台（智税）%'
    or f.YJGNMC LIKE '%数据管控治理平台%'
    or f.YJGNMC LIKE '%增值税发票查询分析系统%'
    or f.YJGNMC LIKE '%纳税人关系云图%'
    or f.YJGNMC LIKE '%票流分析%'
    or f.YJGNMC LIKE '%风险情报系统%'
    or f.YJGNMC LIKE '%风险模型%'
    or f.YJGNMC LIKE '%数据质效考核%'
    or f.YJGNMC LIKE '%自主探索空间%'
    or f.YJGNMC LIKE '%全国纳税人信息查询%'
    or f.YJGNMC LIKE '%出口退税大数据风险监控%'
    or f.YJGNMC LIKE '%专项附加扣除信息核验%'
    or f.YJGNMC LIKE '%用户画像%')
-- 数据有效
 and a.yxbz='Y'
 and b.yxbz='Y'
 and c.yxbz='Y'
 and d.yxbz='Y'
 and f.yxbz='Y'   
 and g.yxbz='Y'
 and h.yxbz='Y'
 and j.yxbz='Y'   
 ;
-- 访问量使用1-9月固定时间，防止每次统计数据情况不一致
-- truncate table ypt_sj_fwqk_arytj1114;
-- create table ypt_sj_fwqk_arytj1114 as 
insert into ypt_sj_fwqk_arytj1114
select
swry_dm        -- 税务人员代码
,swrysf_Dm      -- 税务人员身份代码
,gn_Dm         -- 功能代码
,count(1) as sl   -- 访问量
from hx_zgxt.mh_cygntj k 
where  to_char(lrsj,'yyyymmdd')>='20190101'   -- 限制时间
 -- and to_char(lrsj,'yyyymmdd')<'20191001' 暂时不用这个，直接今年全部
and k.gn_dm in   -- 限制名单
(select gn_dm from hx_bak.ls_wjwjj f where 
    f.YJGNMC LIKE '%上游发票风险传播分析%'
    or f.YJGNMC LIKE '%云平台访问监控统计%'
    or f.YJGNMC LIKE '%全国纳税人涉税风险名录%'
    or f.YJGNMC LIKE '%用户权限管理%'
    or f.YJGNMC LIKE '%纳税人关系分析%'
    or f.YJGNMC LIKE '%数据管控治理平台（智税）%'
    or f.YJGNMC LIKE '%数据管控治理平台%'
    or f.YJGNMC LIKE '%增值税发票查询分析系统%'
    or f.YJGNMC LIKE '%纳税人关系云图%'
    or f.YJGNMC LIKE '%票流分析%'
    or f.YJGNMC LIKE '%风险情报系统%'
    or f.YJGNMC LIKE '%风险模型%'
    or f.YJGNMC LIKE '%数据质效考核%'
    or f.YJGNMC LIKE '%自主探索空间%'
    or f.YJGNMC LIKE '%全国纳税人信息查询%'
    or f.YJGNMC LIKE '%出口退税大数据风险监控%'
    or f.YJGNMC LIKE '%专项附加扣除信息核验%'
    or f.YJGNMC LIKE '%用户画像%')
group by swry_dm,swrysf_Dm ,gn_Dm
 
-- 舍弃效率过低的写法通过核对数据调整代码如下 -- 增加主身份信息
-- truncate table ypt_sj_pzqk_arytj_mx1114;
-- create table  ypt_sj_pzqk_arytj_mx1114 as 
insert into ypt_sj_pzqk_arytj_mx1114
select pz.*,nvl(fw.sl,0) fwl,swjg.swjgmc sjswjgmc
,zsf.rysfmc zsfmc  -- 主身份名称
,swjg1.swjgmc zsfjg -- 主身份机构
from ypt_sj_pzqk_arytj1114 pz -- 配置情况表
left join ypt_sj_fwqk_arytj1114 fw on pz.swry_dm=fw.swry_dm and pz.swrysf_dm=fw.swrysf_dm and pz.gn_dm=fw.gn_dm -- 访问量情况表
left join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=concat(substr(pz.sfswjg_dm,1,3),'00000000')
left join (
  select distinct swjg.swjgmc,sf.sfswjg_dm,sf.swry_dm,sf.swrysf_dm,sf.rysfmc
  from hx_qx.dm_qx_swrysf sf 
  inner join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=sf.sfswjg_dm
  where sf.zsfbz='Y' 
) zsf on zsf.swry_dm=pz.swry_dm and zsf.swrysf_dm=pz.swrysf_dm and zsf.sfswjg_dm=pz.sfswjg_dm 
left join hx_dm_zdy.dm_gy_swjg swjg1 on swjg1.swjg_dm=zsf.sfswjg_dm
 
 
-------------------------------------------------第二次调整------------------------------------------ 
-- 明细数据增加机构层级，上级机构代码，上级机构名称 --明细表 河南 141 重庆 150 广东 144 排除深圳14403

select decode(substr(swjg.jgjc_dm,1,1),'0','总局','1','省级','2','副省级或计划单列市','3','市级','4','区县级','5','乡镇级','6','股级',swjg.jgjc_dm) jgjc,  -- 机构层级
sjswjg.swjg_dm as sjjgdm,  --上级机构代码
sjswjg.swjgmc as sjjgmc    -- 上级机构名称
,rymx.*   -- 上次明细表内容
from ypt_sj_pzqk_arytj_mx1114 rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '141%'  -- and rymx.sfswjg_dm not like '14403%'  -- 用来分省局导出

--同一上级机构代码的机构名称个数  同一机构名称中的功能代码数量 ,第二次电话要求增加机构配置的人员数量 
--按税务机构汇总表 这个上级机构个数应该是汇总表的上级机构个数
select decode(substr(swjg.jgjc_dm,1,1),'0','总局','1','省级','2','副省级或计划单列市','3','市级','4','区县级','5','乡镇级','6','股级',swjg.jgjc_dm) jgjc,  -- 机构级次
sjswjg.swjg_dm as sjjgdm  -- 上级机构代码
,sjswjg.swjgmc as sjjgmc,  -- 上级机构名称
count(1) over (partition by sjswjg.swjg_dm) sjjggs,  -- 计算上级机构个数
rymx.sfswjg_dm -- 身份所属税务机构代码
,rymx.swjgmc  -- 所属税务机构名称
,count(distinct rymx.gn_dm) gns -- 功能数量
,count(distinct rymx.swry_dm) rs  -- 税务人员数量
from ypt_sj_pzqk_arytj_mx1114 rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '141%'  -- and rymx.sfswjg_dm not like '14403%'  -- 用来分省局导出
group by swjg.jgjc_dm,sjswjg.swjg_dm,sjswjg.swjgmc,rymx.sfswjg_dm,rymx.swjgmc




/*
-- 验证
select * from hx_dm_zdy.dm_gy_swjg where swjgmc like '%河南省税务局%'

select * from 

SELECT aa.yjgnmc,count(1) fwl
  FROM hx_zgxt.mh_cygntj jl
 inner join (select gn_dm,YJGNMC
               from hx_bak.ls_wjwjj f
              where f.YJGNMC LIKE '%票流分析%'
                 or f.YJGNMC LIKE '%画像%'
                 or f.YJGNMC LIKE '%纳税人关系云图%'
                 or f.YJGNMC LIKE '%纳税人关系分析%'
                 or f.YJGNMC LIKE '%增值税发票查询分析%') aa
      on jl.gn_dm=aa.gn_dm
	  WHERE to_char(jl.lrsj,'yyyymm') ='201910'
	group by aa.yjgnmc
  
  
  select * from hx_qx.qx_dlzhxx
  where yxbz='Y'
   group by swry_dm
  having count(distinct dlzh_dm)>1
		
    

    
    group by gn_Dm,gnmc
   */
    
