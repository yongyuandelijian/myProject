
select 
nvl(substr(swjgmc,1,instr(swjgmc,'ʡ˰���')+3),substr(swjgmc,1,instr(swjgmc,'������˰���')+5)) jgmc,
gn_dm,gnmc,nvl(count(distinct t.swry_dm),0) rs
from ypt_sj_pzqk_arytj_mx t
where swjgmc like '%ʡ˰���%' or swjgmc like '%������˰���%'
group by gn_dm,gnmc,nvl(substr(swjgmc,1,instr(swjgmc,'ʡ˰���')+3),substr(swjgmc,1,instr(swjgmc,'������˰���')+5))


-- ��λ��

-- ʡ���Ĳ��֣�27  1463
-- ��һ���ֵ�λ�Ǻ�����ʡ˰��֣��͹���˰���ֺܾ�����ʡ˰��ֲ�һ�µ���,������Ҫ�����滻
select mx.* from 
(
  select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(replace(swjgmc,'����˰���ܾ�',''),1,instr(replace(swjgmc,'����˰���ܾ�',''),'ʡ˰���')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  -- distinct t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'˰���')+2)
  from ypt_sj_pzqk_arytj_mx t
  where swjgmc like '%ʡ˰���%'
  group by t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(replace(swjgmc,'����˰���ܾ�',''),1,instr(replace(swjgmc,'����˰���ܾ�',''),'ʡ˰���')+3)
  union all
  -- �������Ĳ���
  select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'������˰���')+5) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from ypt_sj_pzqk_arytj_mx t
  where swjgmc like '%������˰���%'
  group by t.gn_dm,t.gnmc,t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'������˰���')+5)
) mx

-- �м���
-- ���ڵ�������ǻ���ڵؼ��У��Ѿ��Ϳͻ�ȷ����ʱ�ͷ����е�������
-- �ڶ���������Ǵ���ԭʲô�����ģ�����ֽ���ȡ��ԭ��ͷ��ֻ��ԭƽ�������ϲ��ᱻӰ��

select mx.* from 
(
  select 
  t.gn_dm,t.gnmc,t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'��˰���')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from 
  (select gn_dm,gnmc,sjswjgmc,regexp_replace(replace(swjgmc,'����˰���ܾ�',''),'^ԭ','') swjgmc,swry_dm,sfswjg_dm from ypt_sj_pzqk_arytj_mx) t
  where swjgmc like '%��˰���%' 
   and swjgmc not like '%������˰���'
   and swjgmc not like '%�����˰���'
   and swjgmc not like '%������˰���'
   and swjgmc not like '%�Ϻ���˰���'
   and swjgmc not like '%������˰���'
   and swjgmc not like '%������˰���'
   and swjgmc not like '%�ൺ��˰���'
   and swjgmc not like '%������˰���'
   and swjgmc not like '%������˰���'
  group by t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'��˰���')+3)
  union all
  -- ������˰���
  select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(replace(swjgmc,'����˰���ܾ�',''),1,instr(replace(swjgmc,'����˰���ܾ�',''),'������˰���')+5) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from (select gn_dm,gnmc,sjswjgmc,regexp_replace(replace(swjgmc,'����˰���ܾ�',''),'^ԭ','') swjgmc,swry_dm,sfswjg_dm from ypt_sj_pzqk_arytj_mx) t
  where swjgmc like '%������˰���%'
  group by t.gn_dm,t.gnmc,t.sjswjgmc,substr(replace(swjgmc,'����˰���ܾ�',''),1,instr(replace(swjgmc,'����˰���ܾ�',''),'������˰���')+5)
) mx

-- ֱϽ�кͼƻ�������
select 
  t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'��˰���')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from 
  (select sjswjgmc,regexp_replace(replace(swjgmc,'����˰���ܾ�',''),'^ԭ','') swjgmc,swry_dm,sfswjg_dm 
   from ypt_sj_pzqk_arytj_mx 
   where swjgmc like '%������˰���%'
   or swjgmc like '%�����˰���%'
   or swjgmc like '%������˰���%'
   or swjgmc like '%�Ϻ���˰���%'
   or swjgmc like '%������˰���%'
   or swjgmc like '%������˰���%'
   or swjgmc like '%�ൺ��˰���%'
   or swjgmc like '%������˰���%'
   or swjgmc like '%������˰���%') t 
  group by t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'��˰���')+3)

-- ���ز���������

 select * from 
 (
 select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'��˰���')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from (select gn_dm,gnmc,sjswjgmc,regexp_replace(replace(swjgmc,'����˰���ܾ�',''),'^ԭ','') swjgmc,swry_dm,sfswjg_dm 
  from ypt_sj_pzqk_arytj_mx where swjgmc like '%��˰���%') t
  group by t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'��˰���')+3)
union all
 select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'��˰���')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from (select gn_dm,gnmc,sjswjgmc,regexp_replace(replace(swjgmc,'����˰���ܾ�',''),'^ԭ','') swjgmc,swry_dm,sfswjg_dm 
  from ypt_sj_pzqk_arytj_mx where swjgmc like '%��˰���%' and swjgmc not like '%������˰���%') t
  group by t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'��˰���')+3)
 )




------------------------------------------------------�˶����ݲ���------------------------------------
-- �˶Ե�λ��
select mx.* from 
(
  select 
  t.sjswjgmc,substr(replace(swjgmc,'����˰���ܾ�',''),1,instr(replace(swjgmc,'����˰���ܾ�',''),'ʡ˰���')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  -- distinct t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'˰���')+2)
  from ypt_sj_pzqk_arytj_mx t
  where swjgmc like '%ʡ˰���%'
  group by t.sjswjgmc,
  substr(replace(swjgmc,'����˰���ܾ�',''),1,instr(replace(swjgmc,'����˰���ܾ�',''),'ʡ˰���')+3)
  union all
  -- �������Ĳ���
  select 
  t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'������˰���')+5) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from ypt_sj_pzqk_arytj_mx t
  where swjgmc like '%������˰���%'
  group by t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'������˰���')+5)
) mx


-- �����ֶ�
select * from 
(select 
  t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'��˰���')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from 
  (select sjswjgmc,regexp_replace(replace(swjgmc,'����˰���ܾ�',''),'^ԭ','') swjgmc,swry_dm,sfswjg_dm 
  from ypt_sj_pzqk_arytj_mx
  where swjgmc like '%��˰���%' ) t
  where swjgmc like '%��˰���%' 
   and swjgmc not like '%������˰���'
   and swjgmc not like '%�����˰���'
   and swjgmc not like '%������˰���'
   and swjgmc not like '%�Ϻ���˰���'
   and swjgmc not like '%������˰���'
   and swjgmc not like '%������˰���'
   and swjgmc not like '%�ൺ��˰���'
   and swjgmc not like '%������˰���'
   and swjgmc not like '%������˰���'
  group by t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'��˰���')+3)) where jgmc like '%����%'
  
  select distinct sfswjg_dm,swjgmc from ypt_sj_pzqk_arytj_mx where swjgmc  like '%������%'
  swjgmc not like '%������˰���'
   and swjgmc not like '%�����˰���'
   or swjgmc not like '%������˰���'
   or swjgmc not like '%�Ϻ���˰���'
   or swjgmc not like '%������˰���'
   or swjgmc not like '%������˰���'
   or swjgmc not like '%�ൺ��˰���'
   or swjgmc not like '%������˰���'
   or swjgmc not like '%������˰���'
