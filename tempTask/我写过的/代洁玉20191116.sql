-- 查询岗位功能配置  select * from hx_dm_zdy.dm_gy_swjg where swjgmc like '%湖南省税务局%'
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
,f.gw_dm 
,gw.gwmc
from  hx_dm_zdy.dm_gy_swry a 
,hx_qx.dm_qx_swrysf b  
,hx_qx.qx_dlzhxx c 
,hx_dm_zdy.dm_gy_swjg d  
,hx_qx.qx_swjg_gw f
,hx_dm_zdy.dm_qx_gw gw
,hx_qx.qx_jggw_swrysf g
,hx_qx.qx_gw_xtgn h
,hx_dm_qg.dm_qx_gns j
where a.swry_Dm = b.swry_dm
and b.sfswjg_dm = d.swjg_dm
and a.swry_dm=c.swry_dm
and f.gwxh=g.gwxh
and g.swrysf_dm=b.swrysf_dm
and b.sfswjg_dm=f.swjg_dm
and f.gw_dm=gw.gw_dm
and f.gw_dm= h.gw_dm 
and h.xtgn_dm = j.xtgn_dm 
and d.swjg_dm like '143%'
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
 and gw.yxbz='Y' 
 ;
