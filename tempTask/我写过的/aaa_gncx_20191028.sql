-- ȫ��˰��������������
select swjg_dm,swjgmc,swjgjc,yxbz,xybz from hx_dm_zdy.dm_gy_swjg 
where swjg_dm='111010179167'
 order by swjg_dm
/*
1 �����㼶����һ����������β����0000��00000 ����000000����0000000����00000000����

00000000000��Ϊ�ؾ֡�
β����000000  ����0000000����00000000����00000000000��Ϊ�о֡�
β����00000000��00000000000��Ϊʡ��
-- �ƻ���������μƻ� �����֣��˹��ж�


2 ͬһ�ϼ���������Ļ������Ƹ���  ͬһ���������еĹ��ܴ�������  


3 ��Ҫ�ֽ�ԭ������Ϊ36���ĵ���ÿ���ĵ�����sheetҳ����������С���첻һ���������
-- ��ϸ��ͳ�������ĵ���ԭ�е���ϸ�ĵ���ԭ�е������������

select distinct jgjc_dm from hx_dm_zdy.dm_gy_swjg order by jgjc_dm
select * from hx_dm_qg.dm_gy_jgjc;


-- ͬһ�ϼ���������Ļ������Ƹ���  ͬһ���������еĹ��ܴ������� ,�ڶ��ε绰Ҫ�����ӻ������õ���Ա���� 
--���2 ����ϼ���������˼·��������ָ���ܱ�ĸ���
select decode(substr(swjg.jgjc_dm,1,1),'0','�ܾ�','1','ʡ��','2','��ʡ����ƻ�������','3','�м�','4','���ؼ�','5','����','6','�ɼ�',swjg.jgjc_dm) jgjc,
sjswjg.swjg_dm as sjjgdm,sjswjg.swjgmc as sjjgmc,count(sjswjg.swjg_dm) sjjgs,
rymx.sfswjg_dm,rymx.swjgmc,count(distinct rymx.gn_dm) gns,count(distinct rymx.swry_dm) rs
from ypt_sj_pzqk_arytj_mx rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '111%'  -- and rymx.sfswjg_dm not like '14403%'  -- ������ʡ�ֵ���
group by swjg.jgjc_dm,sjswjg.swjg_dm,sjswjg.swjgmc,rymx.sfswjg_dm,rymx.swjgmc
*/
-- ��ϸ�������ӻ����㼶���ϼ��������룬�ϼ��������� --���1

select decode(substr(swjg.jgjc_dm,1,1),'0','�ܾ�','1','ʡ��','2','��ʡ����ƻ�������','3','�м�','4','���ؼ�','5','����','6','�ɼ�',swjg.jgjc_dm) jgjc,
sjswjg.swjg_dm as sjjgdm,sjswjg.swjgmc as sjjgmc,rymx.*
from ypt_sj_pzqk_arytj_mx rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '165%'  -- and rymx.sfswjg_dm not like '14403%'  -- ������ʡ�ֵ���

--ͬһ�ϼ���������Ļ������Ƹ���  ͬһ���������еĹ��ܴ������� ,�ڶ��ε绰Ҫ�����ӻ������õ���Ա���� 
--���2 ����ϼ���������Ӧ���ǻ��ܱ���ϼ���������
select decode(substr(swjg.jgjc_dm,1,1),'0','�ܾ�','1','ʡ��','2','��ʡ����ƻ�������','3','�м�','4','���ؼ�','5','����','6','�ɼ�',swjg.jgjc_dm) jgjc,
sjswjg.swjg_dm as sjjgdm,sjswjg.swjgmc as sjjgmc,
count(1) over (partition by sjswjg.swjg_dm) sjjggs,
rymx.sfswjg_dm,rymx.swjgmc,count(distinct rymx.gn_dm) gns,count(distinct rymx.swry_dm) rs
from ypt_sj_pzqk_arytj_mx rymx
left join hx_dm_zdy.dm_gy_swjg swjg on rymx.sfswjg_dm=swjg.swjg_dm
left join hx_dm_zdy.dm_gy_swjg sjswjg on swjg.sjswjg_dm=sjswjg.swjg_dm
where rymx.sfswjg_dm like '111%'  -- and rymx.sfswjg_dm not like '14403%'  -- ������ʡ�ֵ���
group by swjg.jgjc_dm,sjswjg.swjg_dm,sjswjg.swjgmc,rymx.sfswjg_dm,rymx.swjgmc

-- ��֤
select * from ypt_sj_pzqk_arytj_mx mx where mx.sfswjg_dm='16104000100'


