
select 
nvl(substr(swjgmc,1,instr(swjgmc,'省税务局')+3),substr(swjgmc,1,instr(swjgmc,'自治区税务局')+5)) jgmc,
gn_dm,gnmc,nvl(count(distinct t.swry_dm),0) rs
from ypt_sj_pzqk_arytj_mx t
where swjgmc like '%省税务局%' or swjgmc like '%自治区税务局%'
group by gn_dm,gnmc,nvl(substr(swjgmc,1,instr(swjgmc,'省税务局')+3),substr(swjgmc,1,instr(swjgmc,'自治区税务局')+5))


-- 单位数

-- 省级的部分，27  1463
-- 有一部分单位是黑龙江省税务局，和国家税务总局黑龙江省税务局不一致导致,所以需要进行替换
select mx.* from 
(
  select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(replace(swjgmc,'国家税务总局',''),1,instr(replace(swjgmc,'国家税务总局',''),'省税务局')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  -- distinct t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'税务局')+2)
  from ypt_sj_pzqk_arytj_mx t
  where swjgmc like '%省税务局%'
  group by t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(replace(swjgmc,'国家税务总局',''),1,instr(replace(swjgmc,'国家税务总局',''),'省税务局')+3)
  union all
  -- 自治区的部分
  select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'自治区税务局')+5) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from ypt_sj_pzqk_arytj_mx t
  where swjgmc like '%自治区税务局%'
  group by t.gn_dm,t.gnmc,t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'自治区税务局')+5)
) mx

-- 市级，
-- 存在的问题就是会存在地级市，已经和客户确认暂时就放在市的名单内
-- 第二个问题就是存在原什么机构的，这个字进行取消原开头的只有原平市理论上不会被影响

select mx.* from 
(
  select 
  t.gn_dm,t.gnmc,t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'市税务局')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from 
  (select gn_dm,gnmc,sjswjgmc,regexp_replace(replace(swjgmc,'国家税务总局',''),'^原','') swjgmc,swry_dm,sfswjg_dm from ypt_sj_pzqk_arytj_mx) t
  where swjgmc like '%市税务局%' 
   and swjgmc not like '%北京市税务局'
   and swjgmc not like '%天津市税务局'
   and swjgmc not like '%大连市税务局'
   and swjgmc not like '%上海市税务局'
   and swjgmc not like '%宁波市税务局'
   and swjgmc not like '%厦门市税务局'
   and swjgmc not like '%青岛市税务局'
   and swjgmc not like '%深圳市税务局'
   and swjgmc not like '%重庆市税务局'
  group by t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'市税务局')+3)
  union all
  -- 自治州税务局
  select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(replace(swjgmc,'国家税务总局',''),1,instr(replace(swjgmc,'国家税务总局',''),'自治州税务局')+5) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from (select gn_dm,gnmc,sjswjgmc,regexp_replace(replace(swjgmc,'国家税务总局',''),'^原','') swjgmc,swry_dm,sfswjg_dm from ypt_sj_pzqk_arytj_mx) t
  where swjgmc like '%自治州税务局%'
  group by t.gn_dm,t.gnmc,t.sjswjgmc,substr(replace(swjgmc,'国家税务总局',''),1,instr(replace(swjgmc,'国家税务总局',''),'自治州税务局')+5)
) mx

-- 直辖市和计划单列市
select 
  t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'市税务局')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from 
  (select sjswjgmc,regexp_replace(replace(swjgmc,'国家税务总局',''),'^原','') swjgmc,swry_dm,sfswjg_dm 
   from ypt_sj_pzqk_arytj_mx 
   where swjgmc like '%北京市税务局%'
   or swjgmc like '%天津市税务局%'
   or swjgmc like '%大连市税务局%'
   or swjgmc like '%上海市税务局%'
   or swjgmc like '%宁波市税务局%'
   or swjgmc like '%厦门市税务局%'
   or swjgmc like '%青岛市税务局%'
   or swjgmc like '%深圳市税务局%'
   or swjgmc like '%重庆市税务局%') t 
  group by t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'市税务局')+3)

-- 区县不含自治区

 select * from 
 (
 select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'县税务局')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from (select gn_dm,gnmc,sjswjgmc,regexp_replace(replace(swjgmc,'国家税务总局',''),'^原','') swjgmc,swry_dm,sfswjg_dm 
  from ypt_sj_pzqk_arytj_mx where swjgmc like '%县税务局%') t
  group by t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'县税务局')+3)
union all
 select 
  t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'区税务局')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from (select gn_dm,gnmc,sjswjgmc,regexp_replace(replace(swjgmc,'国家税务总局',''),'^原','') swjgmc,swry_dm,sfswjg_dm 
  from ypt_sj_pzqk_arytj_mx where swjgmc like '%区税务局%' and swjgmc not like '%自治区税务局%') t
  group by t.gn_dm,t.gnmc,t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'区税务局')+3)
 )




------------------------------------------------------核对数据部分------------------------------------
-- 核对单位数
select mx.* from 
(
  select 
  t.sjswjgmc,substr(replace(swjgmc,'国家税务总局',''),1,instr(replace(swjgmc,'国家税务总局',''),'省税务局')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  -- distinct t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'税务局')+2)
  from ypt_sj_pzqk_arytj_mx t
  where swjgmc like '%省税务局%'
  group by t.sjswjgmc,
  substr(replace(swjgmc,'国家税务总局',''),1,instr(replace(swjgmc,'国家税务总局',''),'省税务局')+3)
  union all
  -- 自治区的部分
  select 
  t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'自治区税务局')+5) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from ypt_sj_pzqk_arytj_mx t
  where swjgmc like '%自治区税务局%'
  group by t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'自治区税务局')+5)
) mx


-- 测试字段
select * from 
(select 
  t.sjswjgmc,substr(swjgmc,1,instr(swjgmc,'市税务局')+3) jgmc,
  nvl(count(distinct t.swry_dm),0) rs
  from 
  (select sjswjgmc,regexp_replace(replace(swjgmc,'国家税务总局',''),'^原','') swjgmc,swry_dm,sfswjg_dm 
  from ypt_sj_pzqk_arytj_mx
  where swjgmc like '%市税务局%' ) t
  where swjgmc like '%市税务局%' 
   and swjgmc not like '%北京市税务局'
   and swjgmc not like '%天津市税务局'
   and swjgmc not like '%大连市税务局'
   and swjgmc not like '%上海市税务局'
   and swjgmc not like '%宁波市税务局'
   and swjgmc not like '%厦门市税务局'
   and swjgmc not like '%青岛市税务局'
   and swjgmc not like '%深圳市税务局'
   and swjgmc not like '%重庆市税务局'
  group by t.sjswjgmc,
  substr(swjgmc,1,instr(swjgmc,'市税务局')+3)) where jgmc like '%胶州%'
  
  select distinct sfswjg_dm,swjgmc from ypt_sj_pzqk_arytj_mx where swjgmc  like '%胶州市%'
  swjgmc not like '%北京市税务局'
   and swjgmc not like '%天津市税务局'
   or swjgmc not like '%大连市税务局'
   or swjgmc not like '%上海市税务局'
   or swjgmc not like '%宁波市税务局'
   or swjgmc not like '%厦门市税务局'
   or swjgmc not like '%青岛市税务局'
   or swjgmc not like '%深圳市税务局'
   or swjgmc not like '%重庆市税务局'
