-------���ƣ�ƽ̨����Ӧ�÷���������top5------
--������������ 20191028
--ģ�飺����ƽ̨Ӧ��ʹ�������
--��ϵ�ˣ��ַ�����ʤ��ʦ
--���Σ� hx_dm_zdy.dm_gy_swry  ˰����Ա����
--        ˰����Ա��ݴ����
--        ��¼�˻���Ϣ��
--       ˰���������
--          ˰����ظ�λ���ձ�
--       ������λ˰����Ա���
--          Ȩ��ϵͳ����
--        ������
--        ��λ
--         �Ż����ù���ͳ��


-- �����ṩ��һ�����ܲ˵����Ʋ�ѯ��ָ������������Ա�������
-- truncate table ypt_sj_pzqk_arytj1114;
-- create table ypt_sj_pzqk_arytj1114 as 
insert into ypt_sj_pzqk_arytj1114
select  
distinct c.dlzh_dm  -- ��½�˺Ŵ���
,a.swry_dm        -- ˰����Ա����
,a.swryxm         -- ˰����Ա����
,a.sfzjhm         -- ���֤������
,b.swrysf_dm       -- ˰����Ա��ݴ���
,b.rysfmc         -- ˰����Ա�������
,b.sfswjg_dm       -- �������˰���������
,d.swjgmc         -- �������˰���������
,j.gn_dm          -- ���ܴ���
,j.gnmc           -- �������� 
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
-- ���˹�������
and j.gn_dm in 
(select gn_dm from hx_bak.ls_wjwjj f where 
    f.YJGNMC LIKE '%���η�Ʊ���մ�������%'
    or f.YJGNMC LIKE '%��ƽ̨���ʼ��ͳ��%'
    or f.YJGNMC LIKE '%ȫ����˰����˰������¼%'
    or f.YJGNMC LIKE '%�û�Ȩ�޹���%'
    or f.YJGNMC LIKE '%��˰�˹�ϵ����%'
    or f.YJGNMC LIKE '%���ݹܿ�����ƽ̨����˰��%'
    or f.YJGNMC LIKE '%���ݹܿ�����ƽ̨%'
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
    or f.YJGNMC LIKE '%�û�����%')
-- ������Ч
 and a.yxbz='Y'
 and b.yxbz='Y'
 and c.yxbz='Y'
 and d.yxbz='Y'
 and f.yxbz='Y'   
 and g.yxbz='Y'
 and h.yxbz='Y'
 and j.yxbz='Y'   
 ;
-- ������ʹ��1-9�¹̶�ʱ�䣬��ֹÿ��ͳ�����������һ��
-- truncate table ypt_sj_fwqk_arytj1114;
-- create table ypt_sj_fwqk_arytj1114 as 
insert into ypt_sj_fwqk_arytj1114
select
swry_dm        -- ˰����Ա����
,swrysf_Dm      -- ˰����Ա��ݴ���
,gn_Dm         -- ���ܴ���
,count(1) as sl   -- ������
from hx_zgxt.mh_cygntj k 
where  to_char(lrsj,'yyyymmdd')>='20190101'   -- ����ʱ��
 -- and to_char(lrsj,'yyyymmdd')<'20191001' ��ʱ���������ֱ�ӽ���ȫ��
and k.gn_dm in   -- ��������
(select gn_dm from hx_bak.ls_wjwjj f where 
    f.YJGNMC LIKE '%���η�Ʊ���մ�������%'
    or f.YJGNMC LIKE '%��ƽ̨���ʼ��ͳ��%'
    or f.YJGNMC LIKE '%ȫ����˰����˰������¼%'
    or f.YJGNMC LIKE '%�û�Ȩ�޹���%'
    or f.YJGNMC LIKE '%��˰�˹�ϵ����%'
    or f.YJGNMC LIKE '%���ݹܿ�����ƽ̨����˰��%'
    or f.YJGNMC LIKE '%���ݹܿ�����ƽ̨%'
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
    or f.YJGNMC LIKE '%�û�����%')
group by swry_dm,swrysf_Dm ,gn_Dm
 
-- ����Ч�ʹ��͵�д��ͨ���˶����ݵ����������� -- �����������Ϣ
-- truncate table ypt_sj_pzqk_arytj_mx1114;
-- create table  ypt_sj_pzqk_arytj_mx1114 as 
insert into ypt_sj_pzqk_arytj_mx1114
select pz.*,nvl(fw.sl,0) fwl,swjg.swjgmc sjswjgmc
,zsf.rysfmc zsfmc  -- ���������
,swjg1.swjgmc zsfjg -- ����ݻ���
from ypt_sj_pzqk_arytj1114 pz -- ���������
left join ypt_sj_fwqk_arytj1114 fw on pz.swry_dm=fw.swry_dm and pz.swrysf_dm=fw.swrysf_dm and pz.gn_dm=fw.gn_dm -- �����������
left join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=concat(substr(pz.sfswjg_dm,1,3),'00000000')
left join (
  select distinct swjg.swjgmc,sf.sfswjg_dm,sf.swry_dm,sf.swrysf_dm,sf.rysfmc
  from hx_qx.dm_qx_swrysf sf 
  inner join hx_dm_zdy.dm_gy_swjg swjg on swjg.swjg_dm=sf.sfswjg_dm
  where sf.zsfbz='Y' 
) zsf on zsf.swry_dm=pz.swry_dm and zsf.swrysf_dm=pz.swrysf_dm and zsf.sfswjg_dm=pz.sfswjg_dm 
left join hx_dm_zdy.dm_gy_swjg swjg1 on swjg1.swjg_dm=zsf.sfswjg_dm
 
 
-------------------------------------------------�ڶ��ε���------------------------------------------ 
-- ��ϸ�������ӻ����㼶���ϼ��������룬�ϼ��������� --��ϸ�� ���� 141 ���� 150 �㶫 144 �ų�����14403

select decode(substr(swjg.jgjc_dm,1,1),'0','�ܾ�','1','ʡ��','2','��ʡ����ƻ�������','3','�м�','4','���ؼ�','5','����','6','�ɼ�',swjg.jgjc_dm) jgjc,  -- �����㼶
sjswjg.swjg_dm as sjjgdm,  --�ϼ���������
sjswjg.swjgmc as sjjgmc    -- �ϼ���������
,rymx.*   -- �ϴ���ϸ������
from ypt_sj_pzqk_arytj_mx1114 rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '141%'  -- and rymx.sfswjg_dm not like '14403%'  -- ������ʡ�ֵ���

--ͬһ�ϼ���������Ļ������Ƹ���  ͬһ���������еĹ��ܴ������� ,�ڶ��ε绰Ҫ�����ӻ������õ���Ա���� 
--��˰��������ܱ� ����ϼ���������Ӧ���ǻ��ܱ���ϼ���������
select decode(substr(swjg.jgjc_dm,1,1),'0','�ܾ�','1','ʡ��','2','��ʡ����ƻ�������','3','�м�','4','���ؼ�','5','����','6','�ɼ�',swjg.jgjc_dm) jgjc,  -- ��������
sjswjg.swjg_dm as sjjgdm  -- �ϼ���������
,sjswjg.swjgmc as sjjgmc,  -- �ϼ���������
count(1) over (partition by sjswjg.swjg_dm) sjjggs,  -- �����ϼ���������
rymx.sfswjg_dm -- �������˰���������
,rymx.swjgmc  -- ����˰���������
,count(distinct rymx.gn_dm) gns -- ��������
,count(distinct rymx.swry_dm) rs  -- ˰����Ա����
from ypt_sj_pzqk_arytj_mx1114 rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '141%'  -- and rymx.sfswjg_dm not like '14403%'  -- ������ʡ�ֵ���
group by swjg.jgjc_dm,sjswjg.swjg_dm,sjswjg.swjgmc,rymx.sfswjg_dm,rymx.swjgmc




/*
-- ��֤
select * from hx_dm_zdy.dm_gy_swjg where swjgmc like '%����ʡ˰���%'

select * from 

SELECT aa.yjgnmc,count(1) fwl
  FROM hx_zgxt.mh_cygntj jl
 inner join (select gn_dm,YJGNMC
               from hx_bak.ls_wjwjj f
              where f.YJGNMC LIKE '%Ʊ������%'
                 or f.YJGNMC LIKE '%����%'
                 or f.YJGNMC LIKE '%��˰�˹�ϵ��ͼ%'
                 or f.YJGNMC LIKE '%��˰�˹�ϵ����%'
                 or f.YJGNMC LIKE '%��ֵ˰��Ʊ��ѯ����%') aa
      on jl.gn_dm=aa.gn_dm
	  WHERE to_char(jl.lrsj,'yyyymm') ='201910'
	group by aa.yjgnmc
  
  
  select * from hx_qx.qx_dlzhxx
  where yxbz='Y'
   group by swry_dm
  having count(distinct dlzh_dm)>1
		
    

    
    group by gn_Dm,gnmc
   */
    
