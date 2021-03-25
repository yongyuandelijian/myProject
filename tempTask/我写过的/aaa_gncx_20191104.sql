select count(1) from v_ypt_sj_pzqk_tj where sfswjg_dm like '122%'
-- 统计吉林的功能配置和访问量
create table aaa_jlgnpz_20191104 as
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
and b.sfswjg_dm like '122%'
 and a.yxbz='Y'
 and b.yxbz='Y'
 and c.yxbz='Y'
 and d.yxbz='Y'
 and f.yxbz='Y'   
 and g.yxbz='Y'
 and h.yxbz='Y'
 and j.yxbz='Y'   
 ;
 
 -- 关联访问量  aaa_jlgnpz_20191104
 
select pz.*,nvl(fw.sl,0) sl,swjg.swjgmc sjswjgmc,zsf.rysfmc zsfmc,swjg1.swjgmc zsfjg
from aaa_jlgnpz_20191104 pz
left join ypt_sj_fwqk_arytj fw on pz.swry_dm=fw.swry_dm and pz.swrysf_dm=fw.swrysf_dm and pz.gn_dm=fw.gn_dm
left join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=concat(substr(pz.sfswjg_dm,1,3),'00000000')
left join (
  select distinct swjg.swjgmc,sf.sfswjg_dm,sf.swry_dm,sf.swrysf_dm,sf.rysfmc
  from hx_qx.dm_qx_swrysf sf 
  inner join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=sf.sfswjg_dm
  where sf.zsfbz='Y' 
) zsf on zsf.swry_dm=pz.swry_dm and zsf.swrysf_dm=pz.swrysf_dm and zsf.sfswjg_dm=pz.sfswjg_dm 
left join hx_dm_zdy.dm_gy_swjg swjg1 on swjg1.swjg_dm=zsf.sfswjg_dm
