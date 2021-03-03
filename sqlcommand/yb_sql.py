import time
import calendar
class sqlstr(object):
    '''功能：定义月报使用到的sql语句'''
    dqsj = time.localtime(time.time())
    nf=str(dqsj.tm_year)
    yf=str(dqsj.tm_mon-1)
    # 上面暂时先注销
    # nf='2020'
    # yf='09'


    # nf=str(temp_nf)
    # yf=str(temp_yf)
    # syd=calendar.monthrange(temp_nf,temp_yf)[1]
    # ssyd=calendar.monthrange(temp_nf,temp_yf-1)[1]
    # print(syd,ssyd)

    if len(yf)==1:
        yf="0"+yf
    ny=nf + yf  # 有一个默认年月，就是上个月

    def __init__(self,ny):
        if len(ny)==6:
            self.ny = ny
        else:
            print("传入的年月应该为6位比如202006，当前传入的是{ny},传入不合法使用默认值{mrny}".format(ny=ny,mrny=self.ny))

    # 表3.2 异常进程按天汇总
    __b32_ycjc = '''
    SELECT
    	a1.gmtdate,
    	ifnull( a2.count, 0 ) AS jcs,
    	ifnull( a2.dwmcs, '' ) AS zwdwmcs 
    FROM
    	( SELECT substr(filename, 1, 8 ) gmtdate FROM ggsinfo WHERE filename LIKE '{ny}%' group by substr( `filename`, 1, 8 ) ) a1
    	LEFT JOIN (
    	SELECT
    		b.gmtdate,
    		SUM( b.cnt ) AS count,
    		GROUP_CONCAT( b.pro_mc ) AS dwmcs 
    	FROM
    		(
    		SELECT
    			a.pro_mc,
    			a.gmtdate,
    			count( DISTINCT a.group1 ) AS cnt 
    		FROM
    			(
    			SELECT
    				pro_mc,
    				substr( `filename`, 1, 8 ) AS gmtdate,
    				`group1` 
    			FROM
    				`ggsinfo` t1
    				LEFT JOIN pro_dm_36 t2 ON t1.project = RIGHT ( t2.pro_dm, 4 ) 
    			WHERE
    				`filename` LIKE '{ny}%' 
    				AND `status1` = 'ABENDED' 
    			) a 
    		GROUP BY
    			pro_mc,
    			a.gmtdate 
    		) b 
    	GROUP BY
    		b.gmtdate 
    	ORDER BY
    	b.gmtdate 
    	) a2 ON a1.gmtdate = a2.gmtdate;
    '''.format(ny=ny)
    def get_b32_ycjc(self):
        return self.__b32_ycjc

    # 分发库异常情况分单位
    __b32_ffkyc_fdw='''
    select replace(REPLACE(pro_mc,'税务',''),'内蒙','内蒙古') dw,sum(cnt) zs from 
    (
    SELECT
        a.pro_mc,
        a.gmtdate,
        count( DISTINCT a.group1 ) AS cnt 
    FROM
        (
        SELECT
            pro_mc,
            substr( `filename`, 1, 8 ) AS gmtdate,
            `group1` 
        FROM
            `ggsinfo` t1
            LEFT JOIN pro_dm_36 t2 ON t1.project = RIGHT ( t2.pro_dm, 4 ) 
        WHERE
            `filename` LIKE '{ny}%' 
            AND `status1` = 'ABENDED' 
        ) a 
    GROUP BY
        pro_mc,
        a.gmtdate 
    ) mx group by pro_mc;
    '''.format(ny=ny)
    def get_b32_ffkyc_fdw(self):
        return self.__b32_ffkyc_fdw

    # 分发库异常分日期
    __zj32_ffkyc_frq='''
    select gmtdate,sum(cnt) zs from 
    (
    SELECT
        a.pro_mc,
        a.gmtdate,
        count( DISTINCT a.group1 ) AS cnt 
    FROM
        (
        SELECT
            pro_mc,
            substr( `filename`, 1, 8 ) AS gmtdate,
            `group1` 
        FROM
            `ggsinfo` t1
            LEFT JOIN pro_dm_36 t2 ON t1.project = RIGHT ( t2.pro_dm, 4 ) 
        WHERE
            `filename` LIKE '{ny}%' 
            AND `status1` = 'ABENDED' 
        ) a 
    GROUP BY
        pro_mc,
        a.gmtdate 
    ) mx group by gmtdate;
    '''.format(ny=ny)
    def get_zj32_ffkyc_frq(self):
        return self.__zj32_ffkyc_frq

    # 422 任务异常分日期
    __zj422_rwyc_frq = """
    select rq.gmtdate,ifnull(mx.rws,0) ycs FROM
    (select substr(filename,1,8) gmtdate from ggsinfo where filename like '{ny}%' group by substr(filename,1,8)) rq
    left join 
    (SELECT bizdate, count(1) AS rws FROM operator_info WHERE bizdate LIKE '{ny}%' GROUP BY bizdate) mx
    on mx.bizdate=rq.gmtdate
    order by rq.gmtdate
    """.format(ny=ny)

    def get_zj422_rwyc_frq(self):
        return self.__zj422_rwyc_frq

    # 4203 任务异常分日期  总结
    __zj4203_rwyc_frq = """SELECT bizdate, count(1) AS rws FROM operator_info WHERE bizdate LIKE '{ny}%' GROUP BY bizdate order by rws desc;""".format(ny=ny)

    def get_zj4203_rwyc_frq(self):
        return self.__zj4203_rwyc_frq


    # 表42任务异常分单位汇总
    __b42_rwyc_fdw = '''
    SELECT
    	replace(REPLACE(b.pro_mc,'税务',''),'内蒙','内蒙古') dw,
    	ifnull( a.sbs, 0 ) AS count 
    FROM
    	( SELECT * FROM pro_dm_36 WHERE pro_dm LIKE 'sc_jx___st' UNION SELECT * FROM pro_dm_36 WHERE pro_dm LIKE '%_GSZJ' ) b
    	LEFT JOIN ( SELECT project_name AS dwmc, count( 1 ) AS sbs FROM operator_info WHERE bizdate LIKE '{ny}%' GROUP BY project_name ) a ON a.dwmc = b.pro_dm;
    '''.format(ny=ny)
    def get_b42_rwyc_fdw(self):
        return self.__b42_rwyc_fdw

    # 表43异常进程分原因
    __b43_rwyc_fyy = """
    select yy,count(1) cs from 
    (select case when LENGTH(failed_type)<2 then '云平台问题' else failed_type end yy from operator_info where bizdate like '{ny}%') mx
    group by yy;
    """.format(ny=ny)
    def get_b43_rwyc_fyy(self):
        return self.__b43_rwyc_fyy

    # 表41 云平台数据集成情况
    __b41_yptjcbsqk="select fl,lyxt,jcts_jxc,jcts_jcc,rwbs_jxc,rwbs_jcc,tbpl,jcfs from yb_b41_sjjcgs;"
    def get_b41_yptjcbsqk(self):
        return self.__b41_yptjcbsqk
    # 4.2.1总结 新增任务数
    __zj421_xzrwqk="select bsl*2*36 as rwzs,bsl*36 as dcrws,bsl from(select count(distinct tablename) as bsl from new_count_conf where DATE_FORMAT(createtime,'%Y%m')='{ny}') mx;".format(ny=ny)
    def get_zj421_xzrwqk(self):
        return self.__zj421_xzrwqk
    # 4.4 失败任务应对策略
    __b44_sbrwydcl="select @num :=@num+1 as xh,sblx,jcff from yb_b44_sbrwydcl a,(select @num :=0) b;"
    def get_b44_sbrwydcl(self):
        return self.__b44_sbrwydcl

    # 4.5 获取数据一致性抽样比对数据
    __b45_sjyzx="""
    select a.pro_mc,
       c1.FFK as ffk24,
       c2.JC as jc24,
       (c1.FFK - c2.JC) as cy24,
       CONCAT(ROUND(((c1.FFK - c2.JC) / c1.FFK) *100, 2), '%') as cyl24,
       d1.FFK as ffk25,
       d2.JC as jc25,
       (d1.FFK - d2.JC) as cy25,
       CONCAT(ROUND(((d1.FFK - d2.JC) / d1.FFK) *100, 2), '%') as cyl25,
       e1.FFK as ffk26,
       e2.JC as jc26,
       (e1.FFK - e2.JC) as cy26,
       CONCAT(ROUND(((e1.FFK - e2.JC) / e1.FFK) *100, 2), '%') as cyl26,
       f1.FFK as ffk27,
       f2.JC as jc27,
       (f1.FFK - f2.JC) as cy27,
       CONCAT(ROUND(((f1.FFK - f2.JC) / f1.FFK) *100, 2), '%') as cyl27,
       g1.FFK as ffk28,
       g2.JC as jc28,
       (g1.FFK - g2.JC) as cy28,
       CONCAT(ROUND(((g1.FFK - g2.JC) / g1.FFK) *100, 2), '%') as cyl28
  from (SELECT * FROM pro_dm_36 WHERE PRO_DM NOT IN ('SC_JC_GSZJ','SC_JX_GSZJ')) a
  left join(
select projectname, COUNT1 FFK from NEW_CTABLE_FFK where BIZDATE= '{ny}24' and jobname= '{tablename}') C1 
on a.pro_dm= C1.projectname
  left join(
select projectname, (CASE WHEN COUNT2 IS NULL THEN 'NULL' ELSE COUNT2 END) JC from NEW_CTABLE_ODPS where BIZDATE= '{ny}24' and jobname= '{tablename}') C2 
on a.pro_dm= C2.projectname
   left join(
select projectname, COUNT1 FFK from NEW_CTABLE_FFK where BIZDATE= '{ny}25' and jobname= '{tablename}') D1 
on a.pro_dm= D1.projectname
  left join(
select projectname, (CASE WHEN COUNT2 IS NULL THEN 'NULL' ELSE COUNT2 END) JC from NEW_CTABLE_ODPS where BIZDATE= '{ny}25' and jobname= '{tablename}') D2 
on a.pro_dm= D2.projectname
  left join(
select projectname, COUNT1 FFK from NEW_CTABLE_FFK where BIZDATE= '{ny}26' and jobname= '{tablename}') E1 
on a.pro_dm= E1.projectname
  left join(
select projectname, (CASE WHEN COUNT2 IS NULL THEN 'NULL' ELSE COUNT2 END) JC from NEW_CTABLE_ODPS where BIZDATE= '{ny}26' and jobname= '{tablename}') E2 
on a.pro_dm= E2.projectname
  left join(
select projectname, COUNT1 FFK from NEW_CTABLE_FFK where BIZDATE= '{ny}27' and jobname= '{tablename}') F1 
on a.pro_dm= F1.projectname
  left join(
select projectname, (CASE WHEN COUNT2 IS NULL THEN 'NULL' ELSE COUNT2 END) JC from NEW_CTABLE_ODPS where BIZDATE= '{ny}27' and jobname= '{tablename}') F2 
on a.pro_dm= F2.projectname
  left join(
select projectname, COUNT1 FFK from NEW_CTABLE_FFK where BIZDATE= '{ny}28' and jobname= '{tablename}') G1 
on a.pro_dm= G1.projectname
  left join(
select projectname, (CASE WHEN COUNT2 IS NULL THEN 'NULL' ELSE COUNT2 END) JC from NEW_CTABLE_ODPS where BIZDATE= '{ny}28' and jobname= '{tablename}') G2 
on a.pro_dm= G2.projectname;
    """
    def get_b45_sjyzx(self,tablename):
        return self.__b45_sjyzx.format(ny=self.ny,tablename=tablename)

    # 表46 数据更新情况
    __b46_sjgxqk="select yfq,sjly,al,gx,wgx from wbsjgxqk;"
    def get_b46_sjgxqk(self):
        return self.__b46_sjgxqk

    # 4.5 excel 2 数据差异运维记录
    __b45_sjcyyw="select project_name,bizdate,node_name,failed_type,processing_procedure from operator_info where left(bizdate,6)='{ny}'".format(ny=ny)
    def get_b45_sjcyyw(self):
        return self.__b45_sjcyyw


if __name__ == '__main__':
    sql=sqlstr("20205")
    print(sql.ny)