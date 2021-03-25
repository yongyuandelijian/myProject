select t1.djxh,t1.sjlybz from
(select djxh,sjlybz from sc_jc_gszj.HX_DJ_DJ_NSRXX where rfq='20201222' and ) t1
left join (select djxh,sjlybz_jz as sjlybz from kf_jc_gszj.L_HX_DJ_DJ_NSRXX where rfq='20201222') t0
on t1.djxh=t0.djxh and t1.sjlybz=t0.sjlybz
where t0.djxh is null
	  --- 111847904
	
	-- 划定范围
	select count(1) from sc_jc_gszj.HX_DJ_DJ_NSRXX where rfq='20201222' and to_char(coalesce(xgrq,lrrq),'yyyy-mm-dd')>='2019-09-01' and to_char(coalesce(xgrq,lrrq),'yyyy-mm-dd')<'2020-06-01';  -- t1 31338902
	
	select count(1) from HX_DJ_DJ_NSRXX where date_format(ifnull(xgrq,lrrq),'%Y-%m-%d')>='2019-09-01' and date_format(ifnull(xgrq,lrrq),'%Y-%m-%d')<'2020-06-01';    -- 13728696
	select count(1) from HX_DJ_DJ_NSRXX where xgrq is null;  -- 50309
	
	-- 随机抽取几条看下为什么差距比较大
	
	select t1.* from (select djxh,nsrsbh,nsrmc,nsrzt_dm,djrq,lrrq,xgr_dm,xgrq,zgswj_dm,ssgly_dm,yxbz,sjlybz from sc_jc_gszj.HX_DJ_DJ_NSRXX where rfq='20201222' and to_char(coalesce(xgrq,lrrq),'yyyy-mm-dd')>='2019-09-01' and to_char(coalesce(xgrq,lrrq),'yyyy-mm-dd')<'2020-06-01' ) t1 left join (select djxh,sjlybz_jz as sjlybz from kf_jc_gszj.L_HX_DJ_DJ_NSRXX where rfq='20201222' and to_char(coalesce(xgrq,lrrq),'yyyy-mm-dd')>='2019-09-01' and to_char(coalesce(xgrq,lrrq),'yyyy-mm-dd')<'2020-06-01') t0 on t1.djxh=t0.djxh and t1.sjlybz=t0.sjlybz where t0.djxh is null limit 5; 
	
	-- 校验下其他日期
	select count(1) from (select djxh,nsrsbh,nsrmc,nsrzt_dm,djrq,lrrq,xgr_dm,xgrq,zgswj_dm,ssgly_dm,yxbz,sjlybz from sc_jc_gszj.HX_DJ_DJ_NSRXX where rfq='20201222' and to_char(coalesce(xgrq,lrrq),'yyyymm')='202006' ) t1 left join (select djxh,sjlybz_jz as sjlybz from kf_jc_gszj.L_HX_DJ_DJ_NSRXX where rfq='20201222' and to_char(coalesce(xgrq,lrrq),'yyyymm')='202006') t0 on t1.djxh=t0.djxh and t1.sjlybz=t0.sjlybz where t0.djxh is null; 
	

	
select djxh,nsrsbh,nsrmc,nsrzt_dm,djrq,lrrq,xgr_dm,xgrq,zgswj_dm,ssgly_dm,yxbz,sjlybz_jz as sjlybz from kf_jc_gszj.L_HX_DJ_DJ_NSRXX where rfq='20201222'  and djxh in ('10013100001410000129','10013100001410001600','10013100001410002371','10013100001420000790','10013100001420000871');
	
	
	
	
	
	
	
	
	
	
	
	select 74332531-59799994 as a,31338902-13728696 as b    -- | 14532537 | 17610206 |
	
	select min(LRRQ),min(DJRQ),min(XGRQ),min(SJTB_SJ) from HX_DJ_DJ_NSRXX where date_format(xgrq,'%Y')>'1900' and date_format(LRRQ,'%Y')>'1900' and date_format(SJTB_SJ,'%Y')>'1900' ;   -- 59799994
	select count(1) from Ls_HX_DJ_DJ_NSRXX;
	
	select count(1) from
(select djxh,sjlybz from sc_jc_gszj.HX_DJ_DJ_NSRXX where rfq='20201222') t1
left join (select djxh,sjlybz_jz as sjlybz from kf_jc_gszj.L_HX_DJ_DJ_NSRXX where rfq='20201222') t0
on t1.djxh=t0.djxh and t1.sjlybz=t0.sjlybz
where t0.djxh is null
	
	
	
	select count(1) from sc_jc_gszj.HX_DJ_DJ_NSRXX where rfq='20201222'  -- 171399673
	
	select count(1) as sjlybz from kf_jc_gszj.L_HX_DJ_DJ_NSRXX where rfq='20201222'   -- 59803022
	
	select count(1) from sc_jc_gszj.HX_DJ_DJ_NSRXX where rfq='20201221'