# import time
# import calendar

class sqlstr(object):
    '''功能：定义月报使用到的sql语句'''

    # 由于属性加载的时间要早于初始化的时间，所以实际上并没有获取到初始化的时候给予变量的值，所以要将字符串格式化放在方法里
    def __init__(self,ny):
        self.nf = ny[:4]
        self.yf = ny[4:]
        # 处理月份不规则的情况
        if len(self.yf) == 1:
            self.yf = "0" + self.yf
        self.ny = self.nf + self.yf  # 有一个默认年月，就是上个月
        print("执行sql查询的年月是：",self.ny)



    # ----------作废修改为从主方法引入----------- #
    # dqsj = time.localtime(time.time())
    # self.nf = str(dqsj.tm_year)
    # self.yf = str(dqsj.tm_mon - 1)
    # --------------------- #
    # nf='2019'
    # yf='12'
    # nf=str(temp_nf)
    # yf=str(temp_yf)
    # syd=calendar.monthrange(temp_nf,temp_yf)[1]
    # ssyd=calendar.monthrange(temp_nf,temp_yf-1)[1]
    # print(syd,ssyd)
    # ----------作废修改为从主方法引入----------- #

    # 月报表2.2 云平台集成情况
    __b22_jcqk='''
    SELECT fl, sjly lyxt, count(tab) bsl, round(sum(sjl) / 10000, 2) sjlwt, round(sum(siz) / 1000 / 1000 / 1000, 2) ccgb, min(tbpl) jcpl, 
    ifnull(max(jcfs),'增量') jcfs,b.llbh,b.cqzt,case when jcyf='202102' then '是' else '' end sfxz
    FROM t_ypt_sjjcqk a
    left join yb_b22_llxtdygx b on a.sjly=b.sjlyxt
    group by fl,sjly
    order by fl desc
    '''
    def get_b22_jcqk(self):
        return self.__b22_jcqk

    # 表3.1.1 异常进程按天汇总
    __b311_ycjc = '''
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
    		GROUP_CONCAT(DISTINCT b.pro_mc ) AS dwmcs 
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
    '''
    def get_b311_ycjc(self):
        return self.__b311_ycjc.format(ny=self.ny)

    # 3.2.1总结 新增任务数
    __zj321_xzrwqk = """
    select mx.bsl*2*36+zjs.zjsl as rwzs,mx.bsl*36+zjs.zjsl as dcrws,mx.bsl+zjs.zjsl bsl
    from(select count(distinct tablename) as bsl from new_count_conf where DATE_FORMAT(createtime,'%Y%m')='{ny}') mx
    inner join (select count(1) zjsl from column_conf where DATE_FORMAT(createtime,'%Y%m')='{ny}') zjs on 1=1
    """
    def get_zj321_xzrwqk(self):
        return self.__zj321_xzrwqk.format(ny=self.ny)

    # 321 任务异常分日期
    __b321_rwyc_frq = """
    select rq.gmtdate,ifnull(mx.rws,0) ycs FROM
    (select substr(filename,1,8) gmtdate from ggsinfo where filename like '{ny}%' group by substr(filename,1,8)) rq
    left join 
    (SELECT bizdate, count(1) AS rws FROM operator_info WHERE bizdate LIKE '{ny}%' GROUP BY bizdate) mx
    on mx.bizdate=rq.gmtdate
    order by rq.gmtdate
    """
    def get_b321_rwyc_frq(self):
        return self.__b321_rwyc_frq.format(ny=self.ny)


    # 表格321任务异常分单位汇总
    __b321_rwyc_fdw = r'''
    SELECT
    cast(@num :=@num+1 as char) xh,
    '{ny}' ny,
    replace(REPLACE(b.pro_mc,'税务',''),'内蒙','内蒙古') dw,
    ifnull(a.sbs, 0) AS count
    FROM
    (SELECT * FROM pro_dm_36) b
    LEFT JOIN (
    SELECT
        project_name AS dwmc,
        count(1) AS sbs
    FROM
        operator_info
    WHERE
        bizdate LIKE '{ny}%'
    GROUP BY
        project_name
    ) a ON a.dwmc = b.pro_dm
    inner join (select @num :=0) c on 1=1;
    '''
    def get_b321_rwyc_fdw(self):
        return self.__b321_rwyc_fdw.format(ny=self.ny)

    # 表322异常进程分原因
    __b322_rwyc_fyy = """
    select yy,count(1) cs from 
    (select case when LENGTH(failed_type)<2 then '云平台问题' else failed_type end yy from operator_info where bizdate like '{ny}%') mx
    group by yy order by cs desc;
    """
    def get_b322_rwyc_fyy(self):
        return self.__b322_rwyc_fyy.format(ny=self.ny)

    # 3.2.3 失败任务应对策略
    __b323_sbrwydcl = "select cast(@num :=@num+1 as char) as xh,sblx,jcff from yb_b44_sbrwydcl a,(select @num :=0) b;"
    def get_b323_sbrwydcl(self):
        return self.__b323_sbrwydcl

    # 3.2.4 获取数据一致性抽样比对数据
    __b324_sjyzx = """
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
    def get_b324_sjyzx(self, tablename):
        return self.__b324_sjyzx.format(ny=self.ny, tablename=tablename)

    # 3.2.4 excel 2 数据差异运维记录
    __b324_sjcyyw = "select project_name,bizdate,node_name,failed_type,processing_procedure,failed_reason,failed_ownership,DATE_FORMAT(found_time,'%Y-%m-%d %h:%m:%d') fxsj,DATE_FORMAT(solve_time,'%Y-%m-%d %h:%m:%d') jjsj from operator_info where left(bizdate,6)='{ny}'"
    def get_b324_sjcyyw(self):
        return self.__b324_sjcyyw.format(ny=self.ny)

    # 表325 数据更新情况
    __b325_sjgxqk = "select cast(@num :=@num+1 as char) as xh,sjly,al,gx,wgx from wbsjgxqk,(select @num :=0) b where yfq='{ny}';"
    def get_b325_sjgxqk(self):
        return self.__b325_sjgxqk.format(ny=self.ny)













    # 分发库异常情况分单位
    __b321_ffkyc_fdw='''
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
    '''
    def get_b32_ffkyc_fdw(self):
        return self.__b321_ffkyc_fdw.format(ny=self.ny)

    # 分发库异常分日期
    __zj321_ffkyc_frq='''
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
    '''
    def get_zj32_ffkyc_frq(self):
        return self.__zj321_ffkyc_frq.format(ny=self.ny)

    # 422 任务异常分日期
    __zj422_rwyc_frq = """
    select rq.gmtdate,ifnull(mx.rws,0) ycs FROM
    (select substr(filename,1,8) gmtdate from ggsinfo where filename like '{ny}%' group by substr(filename,1,8)) rq
    left join 
    (SELECT bizdate, count(1) AS rws FROM operator_info WHERE bizdate LIKE '{ny}%' GROUP BY bizdate) mx
    on mx.bizdate=rq.gmtdate
    order by rq.gmtdate
    """
    def get_zj422_rwyc_frq(self):
        return self.__zj422_rwyc_frq.format(ny=self.ny)

    # 4203 任务异常分日期  总结
    __zj4203_rwyc_frq = """SELECT bizdate, count(1) AS rws FROM operator_info WHERE bizdate LIKE '{ny}%' GROUP BY bizdate order by rws desc;"""
    def get_zj4203_rwyc_frq(self):
        return self.__zj4203_rwyc_frq.format(ny=self.ny)


    # 表42任务异常分单位汇总
    __b42_rwyc_fdw = '''
    SELECT
    	replace(REPLACE(b.pro_mc,'税务',''),'内蒙','内蒙古') dw,
    	ifnull( a.sbs, 0 ) AS count 
    FROM
    	( SELECT * FROM pro_dm_36 WHERE pro_dm LIKE 'sc_jx___st' UNION SELECT * FROM pro_dm_36 WHERE pro_dm LIKE '%_GSZJ' ) b
    	LEFT JOIN ( SELECT project_name AS dwmc, count( 1 ) AS sbs FROM operator_info WHERE bizdate LIKE '{ny}%' GROUP BY project_name ) a ON a.dwmc = b.pro_dm;
    '''
    def get_b42_rwyc_fdw(self):
        return self.__b42_rwyc_fdw.format(ny=self.ny)



    # 表41 云平台数据集成情况
    __b41_yptjcbsqk="select fl,lyxt,jcts_jxc,jcts_jcc,rwbs_jxc,rwbs_jcc,tbpl,jcfs from yb_b41_sjjcgs;"
    def get_b41_yptjcbsqk(self):
        return self.__b41_yptjcbsqk

    # 4203 任务异常分日期  总结
    __zj4203_rwyc_frq = "SELECT bizdate, count(1) AS rws FROM operator_info WHERE bizdate LIKE '{ny}%' GROUP BY bizdate order by rws desc;"

    def get_zj4203_rwyc_frq(self):
        return self.__zj4203_rwyc_frq.format(ny=self.ny)