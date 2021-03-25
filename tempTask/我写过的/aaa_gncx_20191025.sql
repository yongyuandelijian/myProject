-- 配置情况第二版
-- 1 第一核对了昨天明细汇总和按机构汇总江西总数产生不一致的情况，今天核对完全一致，应该是数据统计时差的问题，-- 总数和明细汇总的总数相等 832160	69815
-- 2 增加主身份标识和主身份税务机构  不是主身份标识的记录97404
-- 3 由于明细已经提供给客户，所以使用原明细进行做后期修改，否则的话，这里的脚本可以全部重新运行

-- 

-- select count(1) rc,count(distinct swry_dm) rs from (
create table  v_ypt_sj_pzqk_tj as 

select  
distinct c.dlzh_dm,a.swry_dm,a.swryxm,a.sfzjhm,b.swrysf_dm,b.rysfmc,b.sfswjg_dm,d.swjgmc,j.gn_dm,j.gnmc

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

and j.gn_dm in 
(select gn_dm from hx_bak.ls_wjwjj f where 
    /*f.YJGNMC  LIKE '%法人库查询%'
    or f.YJGNMC LIKE '%总局集中库%'
    or */f.YJGNMC LIKE '%上游发票风险传播分析%'
    or f.YJGNMC LIKE '%云平台访问监控统计%'
    or f.YJGNMC LIKE '%全国纳税人涉税风险名录%'
    --or f.YJGNMC LIKE '%单管户查询%'
    or f.YJGNMC LIKE '%用户权限管理%'
    or f.YJGNMC LIKE '%纳税人关系分析%'
    or f.YJGNMC LIKE '%数据管控治理平台（智税）%'
    or f.YJGNMC LIKE '%数据管控治理平台%'
 --   or f.YJGNMC LIKE '%省局私有空间%'
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
 --   or f.YJGNMC LIKE '%云智税收风险分析%'
    or f.YJGNMC LIKE '%用户画像%')
 
 and a.yxbz='Y'
 and b.yxbz='Y'
 and c.yxbz='Y'
 and d.yxbz='Y'
 and f.yxbz='Y'   
 and g.yxbz='Y'
 and h.yxbz='Y'
 and j.yxbz='Y'   
 ;
  
 select count(1) from ypt_sj_pzqk_arytj
 
 
 -- 汇总的   13600000000	1615	25868    25868	1615
 -- 37625	1615  drop table ypt_sj_pzqk_asjtj  使用明细来进行汇总防止重新跑脚本会产生少量的差异

create table ypt_sj_pzqk_asjtj as  
select aa.*,bb.swjgmc
from 
(
select 
concat(SUBSTR(aa.sfswjg_dm, 1, 3), '00000000') AS swjg_dm
, COUNT(DISTINCT aa.swry_dm) AS sl
, COUNT(1) AS hc
from v_ypt_sj_pzqk_tj  aa
where substr(aa.sfswjg_Dm,1,5) not in ('13702','23702','13502','23502','12102','22102','13302','23302','14403','24403') 
group by
concat(SUBSTR(aa.sfswjg_dm, 1, 3), '00000000')  
union all
select 
concat(SUBSTR(aa.sfswjg_dm, 1, 5), '000000')   AS swjg_dm
, COUNT(DISTINCT aa.swry_dm) AS sl
, COUNT(1) AS hc
from
v_ypt_sj_pzqk_tj aa
where  (aa.sfswjg_Dm LIKE '13702%' OR aa.sfswjg_Dm LIKE '23702%' OR
               aa.sfswjg_Dm LIKE '13502%' OR aa.sfswjg_Dm LIKE '23502%' OR
               aa.sfswjg_Dm LIKE '12102%' OR aa.sfswjg_Dm LIKE '22102%' OR
               aa.sfswjg_Dm LIKE '13302%' OR aa.sfswjg_Dm LIKE '23302%' OR
               aa.sfswjg_Dm LIKE '14403%' OR aa.sfswjg_Dm LIKE '24403%')  
group by
concat(SUBSTR(aa.sfswjg_dm, 1, 5), '000000')   
)aa,hx_dm_zdy.dm_gy_swjg bb
where aa.swjg_Dm = bb.swjg_dm 
 
select * from ypt_sj_pzqk_asjtj

-- 访问量还没有提供使用新缓存的数据
create table ypt_sj_fwqk_arytj as 
select
swry_dm,swrysf_Dm ,gn_Dm,count(1) as sl 
from hx_zgxt.mh_cygntj k 
where  to_char(lrsj,'yyyymmdd')>='20190101' 
 and to_char(lrsj,'yyyymmdd')<'20191001'
 -- and swry_dm ='11101060551'
and k.gn_dm in 
(select gn_dm from hx_bak.ls_wjwjj f where 
    /*f.YJGNMC  LIKE '%法人库查询%'
    or f.YJGNMC LIKE '%总局集中库%'
    or */f.YJGNMC LIKE '%上游发票风险传播分析%'
    or f.YJGNMC LIKE '%云平台访问监控统计%'
    or f.YJGNMC LIKE '%全国纳税人涉税风险名录%'
    --or f.YJGNMC LIKE '%单管户查询%'
    or f.YJGNMC LIKE '%用户权限管理%'
    or f.YJGNMC LIKE '%纳税人关系分析%'
    or f.YJGNMC LIKE '%数据管控治理平台（智税）%'
    or f.YJGNMC LIKE '%数据管控治理平台%'
 --   or f.YJGNMC LIKE '%省局私有空间%'
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
 --   or f.YJGNMC LIKE '%云智税收风险分析%'
    or f.YJGNMC LIKE '%用户画像%')
group by swry_dm,swrysf_Dm ,gn_Dm


-- 使用客户已经确认的原明细增加访问量和主身份的列，在增加人员所属的省局名称  云平台配置情况按人员统计表 drop table ypt_sj_pzqk_arytj
create table  ypt_sj_pzqk_arytj 
(
dlzh_dm varchar(30),
swry_dm varchar(30),
swryxm varchar(100),
sfzjhm varchar(30),
swrysf_dm varchar(30),
rysfmc varchar(300),
sfswjg_dm varchar(30),
swjgmc varchar(300),
gn_dm varchar(50),
gnmc varchar(300),
sl varchar(30),
sjswjgmc varchar(300),
zsfmc varchar(200),
zsfjg varchar(300)

);

-- 效率过低作废
create table  ypt_sj_pzqk_arytj_mx as 
select pz.*,nvl(fw.sl,0) sl,swjg.swjgmc sjswjgmc,
(select sf.rysfmc from hx_qx.dm_qx_swrysf sf 
where sf.swry_dm=pz.swry_dm and sf.swrysf_dm=pz.swrysf_dm and sf.sfswjg_dm=pz.sfswjg_dm and sf.zsfbz='Y' 
and to_char(sfyxqz,'YYYY')>='2019' and rownum=1) zsfmc,
(select swjg.swjgmc from hx_qx.dm_qx_swrysf sf 
inner join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=sf.sfswjg_dm
where sf.swry_dm=pz.swry_dm and sf.swrysf_dm=pz.swrysf_dm and sf.sfswjg_dm=pz.sfswjg_dm and sf.zsfbz='Y' 
and to_char(sfyxqz,'YYYY')>='2019' and rownum=1) zsfjg
from v_ypt_sj_pzqk_tj pz
left join ypt_sj_fwqk_arytj fw on pz.swry_dm=fw.swry_dm and pz.swrysf_dm=fw.swrysf_dm and pz.gn_dm=fw.gn_dm
left join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=concat(substr(pz.sfswjg_dm,1,3),'00000000')

-- 使用这个插入明细
create table  ypt_sj_pzqk_arytj_mx as 
select pz.*,nvl(fw.sl,0) sl,swjg.swjgmc sjswjgmc,zsf.rysfmc zsfmc,swjg1.swjgmc zsfjg
from v_ypt_sj_pzqk_tj pz
left join ypt_sj_fwqk_arytj fw on pz.swry_dm=fw.swry_dm and pz.swrysf_dm=fw.swrysf_dm and pz.gn_dm=fw.gn_dm
left join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=concat(substr(pz.sfswjg_dm,1,3),'00000000')
left join (
  select distinct swjg.swjgmc,sf.sfswjg_dm,sf.swry_dm,sf.swrysf_dm,sf.rysfmc
  from hx_qx.dm_qx_swrysf sf 
  inner join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=sf.sfswjg_dm
  where sf.zsfbz='Y' 
) zsf on zsf.swry_dm=pz.swry_dm and zsf.swrysf_dm=pz.swrysf_dm and zsf.sfswjg_dm=pz.sfswjg_dm 
left join hx_dm_zdy.dm_gy_swjg swjg1 on swjg1.swjg_dm=zsf.sfswjg_dm


-- 按省份出数据
select * from ypt_sj_pzqk_arytj_mx t where t.sfswjg_dm like '134%' -- and t.sfswjg_dm not like '14403%'





-- 核对  
select * from ypt_sj_pzqk_asjtj
select count(1) rc,count(distinct swry_dm) rs from  v_ypt_sj_pzqk_tj -- 1	833671	69904
select count(1) rc,count(distinct swry_dm) rs from  ypt_sj_pzqk_arytj -- 1	833671	69904


-- drop table ypt_sj_pzqk_arytj_mx
select substr(t.sfswjg_dm,1,3) jgdm,t.sjswjgmc,count(distinct t.swry_dm) rs,count(1) rc 
from ypt_sj_pzqk_arytj_mx t 
group by substr(t.sfswjg_dm,1,3),t.sjswjgmc
