-- ��������ڶ���
-- 1 ��һ�˶���������ϸ���ܺͰ��������ܽ�������������һ�µ����������˶���ȫһ�£�Ӧ��������ͳ��ʱ������⣬-- ��������ϸ���ܵ�������� 832160	69815
-- 2 ��������ݱ�ʶ�������˰�����  ��������ݱ�ʶ�ļ�¼97404
-- 3 ������ϸ�Ѿ��ṩ���ͻ�������ʹ��ԭ��ϸ�����������޸ģ�����Ļ�������Ľű�����ȫ����������

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
    /*f.YJGNMC  LIKE '%���˿��ѯ%'
    or f.YJGNMC LIKE '%�ּܾ��п�%'
    or */f.YJGNMC LIKE '%���η�Ʊ���մ�������%'
    or f.YJGNMC LIKE '%��ƽ̨���ʼ��ͳ��%'
    or f.YJGNMC LIKE '%ȫ����˰����˰������¼%'
    --or f.YJGNMC LIKE '%���ܻ���ѯ%'
    or f.YJGNMC LIKE '%�û�Ȩ�޹���%'
    or f.YJGNMC LIKE '%��˰�˹�ϵ����%'
    or f.YJGNMC LIKE '%���ݹܿ�����ƽ̨����˰��%'
    or f.YJGNMC LIKE '%���ݹܿ�����ƽ̨%'
 --   or f.YJGNMC LIKE '%ʡ��˽�пռ�%'
    or f.YJGNMC LIKE '%��ֵ˰��Ʊ��ѯ����ϵͳ%'
    or f.YJGNMC LIKE '%��˰�˹�ϵ��ͼ%'
    or f.YJGNMC LIKE '%Ʊ������%'
    or f.YJGNMC LIKE '%�����鱨ϵͳ%'
    or f.YJGNMC LIKE '%����ģ��%'
    or f.YJGNMC LIKE '%������Ч����%'
    or f.YJGNMC LIKE '%����̽���ռ�%'
    or f.YJGNMC LIKE '%ȫ����˰����Ϣ��ѯ%'
    or f.YJGNMC LIKE '%������˰�����ݷ��ռ��%'
    or f.YJGNMC LIKE '%ר��ӿ۳���Ϣ����%'
 --   or f.YJGNMC LIKE '%����˰�շ��շ���%'
    or f.YJGNMC LIKE '%�û�����%')
 
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
 
 
 -- ���ܵ�   13600000000	1615	25868    25868	1615
 -- 37625	1615  drop table ypt_sj_pzqk_asjtj  ʹ����ϸ�����л��ܷ�ֹ�����ܽű�����������Ĳ���

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

-- ��������û���ṩʹ���»��������
create table ypt_sj_fwqk_arytj as 
select
swry_dm,swrysf_Dm ,gn_Dm,count(1) as sl 
from hx_zgxt.mh_cygntj k 
where  to_char(lrsj,'yyyymmdd')>='20190101' 
 and to_char(lrsj,'yyyymmdd')<'20191001'
 -- and swry_dm ='11101060551'
and k.gn_dm in 
(select gn_dm from hx_bak.ls_wjwjj f where 
    /*f.YJGNMC  LIKE '%���˿��ѯ%'
    or f.YJGNMC LIKE '%�ּܾ��п�%'
    or */f.YJGNMC LIKE '%���η�Ʊ���մ�������%'
    or f.YJGNMC LIKE '%��ƽ̨���ʼ��ͳ��%'
    or f.YJGNMC LIKE '%ȫ����˰����˰������¼%'
    --or f.YJGNMC LIKE '%���ܻ���ѯ%'
    or f.YJGNMC LIKE '%�û�Ȩ�޹���%'
    or f.YJGNMC LIKE '%��˰�˹�ϵ����%'
    or f.YJGNMC LIKE '%���ݹܿ�����ƽ̨����˰��%'
    or f.YJGNMC LIKE '%���ݹܿ�����ƽ̨%'
 --   or f.YJGNMC LIKE '%ʡ��˽�пռ�%'
    or f.YJGNMC LIKE '%��ֵ˰��Ʊ��ѯ����ϵͳ%'
    or f.YJGNMC LIKE '%��˰�˹�ϵ��ͼ%'
    or f.YJGNMC LIKE '%Ʊ������%'
    or f.YJGNMC LIKE '%�����鱨ϵͳ%'
    or f.YJGNMC LIKE '%����ģ��%'
    or f.YJGNMC LIKE '%������Ч����%'
    or f.YJGNMC LIKE '%����̽���ռ�%'
    or f.YJGNMC LIKE '%ȫ����˰����Ϣ��ѯ%'
    or f.YJGNMC LIKE '%������˰�����ݷ��ռ��%'
    or f.YJGNMC LIKE '%ר��ӿ۳���Ϣ����%'
 --   or f.YJGNMC LIKE '%����˰�շ��շ���%'
    or f.YJGNMC LIKE '%�û�����%')
group by swry_dm,swrysf_Dm ,gn_Dm


-- ʹ�ÿͻ��Ѿ�ȷ�ϵ�ԭ��ϸ���ӷ�����������ݵ��У���������Ա������ʡ������  ��ƽ̨�����������Աͳ�Ʊ� drop table ypt_sj_pzqk_arytj
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

-- Ч�ʹ�������
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

-- ʹ�����������ϸ
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


-- ��ʡ�ݳ�����
select * from ypt_sj_pzqk_arytj_mx t where t.sfswjg_dm like '134%' -- and t.sfswjg_dm not like '14403%'





-- �˶�  
select * from ypt_sj_pzqk_asjtj
select count(1) rc,count(distinct swry_dm) rs from  v_ypt_sj_pzqk_tj -- 1	833671	69904
select count(1) rc,count(distinct swry_dm) rs from  ypt_sj_pzqk_arytj -- 1	833671	69904


-- drop table ypt_sj_pzqk_arytj_mx
select substr(t.sfswjg_dm,1,3) jgdm,t.sjswjgmc,count(distinct t.swry_dm) rs,count(1) rc 
from ypt_sj_pzqk_arytj_mx t 
group by substr(t.sfswjg_dm,1,3),t.sjswjgmc
