-- ��ѯ��λ��������  select * from hx_dm_zdy.dm_gy_swjg where swjgmc like '%����ʡ˰���%'
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
 and gw.yxbz='Y' 
 ;
