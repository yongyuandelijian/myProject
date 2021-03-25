import calendar
class sqlstr(object):
    '''功能：定义月报使用到的sql语句'''

    # 由于属性加载的时间要早于初始化的时间，所以实际上并没有获取到初始化的时候给予变量的值，所以要将字符串格式化放在方法里
    def __init__(self,ny):
        self.nf = ny[:4]
        self.yf = ny[4:]
        # 处理月份不规则的情况
        if len(self.yf) == 1:
            self.yf = "0" + self.yf
        self.ny = self.nf + self.yf
        # 获取上月来操作环比的表
        self.pre_nf, self.pre_yf = calendar._prevmonth(int(self.nf), int(self.yf))
        if self.pre_yf <10:
            self.pre_yf = "0" + str(self.pre_yf)
        self.pre_ny = str(self.pre_nf) + str(self.pre_yf)
        print("sql中使用的当前年月是{dy},上月是{sy}".format(dy=self.ny, sy=self.pre_ny))

    # 2.1 文字统计
    __tj2101_xzxm="""
    SELECT sscj,ifnull(count(distinct odps_project_name),0) as gs,ifnull(GROUP_CONCAT(distinct odps_project_name),'') as xzxm from zlzyb_odpsproject_info
    where DATE_FORMAT(create_time,'%Y%m')='{ny}'
    group by sscj;
    """
    def get_tj2101_xzxm(self):
        return self.__tj2101_xzxm.format(ny=self.ny)

    # 表2.1 第一个 层级项目数量
    __b2101_cjxmsl="""
    select xx.cjxh,xx.cjmc,ifnull(dy.xms,0) xms,ifnull(dy.xms,0)-ifnull(sy.xms,0) xz from zlzyb_projectlevel_info xx
    left join
    (select sscj,count(DISTINCT odps_project_name) xms from zlzyb_odpsproject_info where DATE_FORMAT(create_time,'%Y%m')<='{ny}' group by sscj) dy
    on xx.cjmc=dy.sscj left join 
    (select sscj,count(DISTINCT odps_project_name) xms from zlzyb_odpsproject_info where DATE_FORMAT(create_time,'%Y%m')<='{pre_ny}' group by sscj) sy
    on xx.cjmc=sy.sscj 
    order by cjxh;
    """
    def get_b2101_cjxmsl(self):
        return self.__b2101_cjxmsl.format(ny=self.ny,pre_ny=self.pre_ny)


    # 表2.1 第二个表 重点项目任务数量分组统计
    __b2102_zdxmrwtj="""
    select xx.cjxh,xx.cjmc,IFNULL(dy.xmsl,0) as xmsl,IFNULL(dy.rwsl,0) as rwsl,(IFNULL(dy.rwsl,0)-IFNULL(sy.rwsl,0)) as zl from zlzyb_projectlevel_info xx
    left join (select sscj,count(DISTINCT odps_project_name) as xmsl,sum(task_num) as rwsl from zlzyb_xmsl_rwsl_rwslzl where tj_ny='{ny}' group by sscj) dy
    on xx.cjmc=dy.sscj
    left join (select sscj,sum(task_num) rwsl from zlzyb_xmsl_rwsl_rwslzl where tj_ny='{pre_ny}' group by sscj) sy
    on xx.cjmc=sy.sscj
    order by xx.cjxh;
    """
    def get_b2102_zdxmrwtj(self):
        return self.__b2102_zdxmrwtj.format(ny=self.ny,pre_ny=self.pre_ny)

    # 表2.1 第3个表 重点项目新增任务数量分组统计
    __b2103_zdxmxzrwtj = """
    select xx.cjxh,xx.cjmc,IFNULL(dy.xzrwsl,0) as xzrwsl,IFNULL(dy.xzrwsl,0)-IFNULL(sy.xzrwsl,0) as zl from zlzyb_projectlevel_info xx
    left join (select sscj,sum(create_task_num) as xzrwsl from zlzyb_create_task_num_tjb where tj_ny='{ny}' group by sscj) dy
    on xx.cjmc=dy.sscj
    left join (select sscj,sum(create_task_num) as xzrwsl from zlzyb_create_task_num_tjb where tj_ny='{pre_ny}' group by sscj) sy
    on dy.sscj=sy.sscj
    order by xx.cjxh;
    """
    def get_b2103_zdxmxzrwtj(self):
        return self.__b2103_zdxmxzrwtj.format(ny=self.ny,pre_ny=self.pre_ny)

    ### 表格22-01 层级任务数量分调度类型统计
    __b2201_fdtlxtj="""
    select xx.cjxh,xx.cjmc,ifnull(sum(mx.rwsl),0) as zs,
    ifnull(sum(case when mx.node_type=0 then mx.rwsl end),0) as zc,
    ifnull(sum(case when mx.node_type=1 then mx.rwsl end),0) as sd,
    ifnull(sum(case when mx.node_type=2 then mx.rwsl end),0) as zt,
    ifnull(sum(case when mx.node_type=4 then mx.rwsl end),0) as kp
    from zlzyb_projectlevel_info xx
    left join zlzyb_node_type_tjb mx on xx.cjmc=mx.sscj
    where mx.tj_ny='{ny}'
    group by xx.cjxh,xx.cjmc
    order by xx.cjxh;
    """
    def get_b2201_fdtlxtj(self):
        return self.__b2201_fdtlxtj.format(ny=self.ny)

    ### 表格23-01 正常调度任务的运行状态分数据层统计
    __b2301_zcrwfyxzttj="""
    select xx.cjxh,xx.cjmc
    ,ifnull(dy.dyzs,0) as dyzs ,ifnull(dy.wyx,0) as wyx ,ifnull(dy.yxz,0) as yxz ,ifnull(dy.sb,0) as sb ,ifnull(dy.cg,0) as cg
    ,ifnull(dy.dyzs,0) -ifnull(sy.syzs,0)  as zl
    from zlzyb_projectlevel_info xx
    left join (
        select cj, sum(inst_num) as dyzs,
        ifnull(sum(case when status=1 then inst_num end),0) as wyx,
        ifnull(sum(case when status=4 then inst_num end),0) as yxz,
        ifnull(sum(case when status=5 then inst_num end),0) as sb,
        ifnull(sum(case when status=6 then inst_num end),0) as cg
        from zlzyb_instance_tjb where tj_ny='{ny}' group by cj
    ) dy on xx.cjmc=dy.cj
    left join (select cj,sum(inst_num) syzs from zlzyb_instance_tjb where tj_ny='{sy}' group by cj) sy on xx.cjmc=sy.cj
    order by xx.cjxh;
    """
    def get_b2301_zcrwfyxzttj(self):
        return self.__b2301_zcrwfyxzttj.format(ny=self.ny,sy=self.pre_ny)
    #===========================  3  ===========================#
    # 统计3101 第一大段镜像层项目数量情况统计
    __tj3101_jxcxm="""
    select count(1) as jxcqb,
    count(case when zdxm='Y' then 1 end) as jxczd 
    from zlzyb_odpsproject_info
    where sscj='镜像层';
    """
    def get_tj3101_jxcxm(self):
        return self.__tj3101_jxcxm

    # 表3101 生产项目空间的任务统计
    __b3101_scrwsltj="""
    select cast(@num :=@num+1 as char) as xh,dy.xmmc,dy.rwsl,dy.rwsl-ifnull(sy.rwsl,0) as zl
    from (select sscj,upper(odps_project_name) as xmmc,sum(task_num) as rwsl from zlzyb_xmsl_rwsl_rwslzl where sscj='{cjmc}' and tj_ny='{dy}' group by sscj,upper(odps_project_name)) dy
    left join (select sscj,upper(odps_project_name) as xmmc,sum(task_num) as rwsl from zlzyb_xmsl_rwsl_rwslzl where sscj='{cjmc}' and tj_ny='{sy}' group by sscj,upper(odps_project_name)) sy
    on dy.sscj=sy.sscj and dy.xmmc=sy.xmmc
    left join (select @num :=0) a on 1=1
    order by dy.xmmc
    """
    def get_b3101_scrwsltj(self):
        return self.__b3101_scrwsltj.format(cjmc="镜像层",dy=self.ny,sy=self.pre_ny)

    # 表3102 镜像层新增任务数，直接从上面的结果获取
    __b3102_scxzrw="""
    select CAST(@num :=@num+1 AS char) as xh,mx.xmmc,mx.xzrwsl from (
    select upper(odps_project_name)as xmmc,sum(create_task_num) as xzrwsl 
    from zlzyb_create_task_num_tjb
    where tj_ny='{dy}' and sscj='{cjmc}'
    group by upper(odps_project_name)
    order by upper(odps_project_name)) mx,(select @num :=0) a;
    """
    def get_b3102_scxzrw(self):
        return self.__b3102_scxzrw.format(cjmc="镜像层",dy=self.ny)

    # 表3201 镜像层调度类型统计任务数
    __b3201_ddlxtjrws="""
    select CAST(@num :=@num+1 AS char) as xh,
    case when node_type=0 then '正常调度' when node_type=1 then '手动调度' when node_type=2 then '暂停调度' when node_type=4 then '空跑调度' else '其他' end zt,
    sum(rwsl) AS sl 
    from zlzyb_node_type_tjb,(select @num :=0) b
    where tj_ny='{dy}' and sscj='{cjmc}'
    group by node_type
    order by node_type;
    """
    def get_b3201_ddlxtjrws(self):
        return self.__b3201_ddlxtjrws.format(cjmc="镜像层",dy=self.ny)

    # 表3202 镜像层正常任务按类型统计
    __b3202_zcrwalxtj="""
    SELECT CAST(@num :=@num+1 AS char) as xh,
    case when prg_type=6 then 'SHELL' 
        when prg_type=10 then 'SQL' 
        when prg_type=11 then 'ODPSMR' 
        when prg_type=23 then '数据集成' 
        when prg_type=98 then '组合节点'
        when prg_type=99 then '虚节点' end as lx,
        sum(rwsl) AS rwsl
    FROM zlzyb_prg_type_tjb a,(select @num :=0) b
    where tj_ny='{dy}' and sscj='{cjmc}'
    group by prg_type;
    """
    def get_b3202_zcrwalxtj(self):
        return self.__b3202_zcrwalxtj.format(cjmc="镜像层",dy=self.ny)

    # 表3301 任务运行状态实例统计
    _b3301_rwyxzttj="""
    select CAST(@num :=@num+1 AS CHAR) xh, 
    case when `status`=1 then '未运行' when `status`=4 then '运行中' when `status`=5 then '失败' when `status`=6 then '成功' end yxzt,
    sum(inst_num) as 实例数 
    from zlzyb_instance_tjb a,(select @num :=0) b
    where tj_ny='{dy}' and cj='{cjmc}'
    group by cj,STATUS;
    """
    def get_b3301_rwyxzttj(self):
        return self._b3301_rwyxzttj.format(cjmc="镜像层",dy=self.ny)

    # 表3302 失败实例统计
    __b3302_sbrwqk = """
    select CAST(@num :=@num+1 AS CHAR) as xh,a.odps_project_name,a.node_name,a.sbcs FROM
    (select t.odps_project_name,t.node_name,count(1) sbcs from zlzyb_inst_mx t
	inner join zlzyb_odpsproject_info b on t.app_id=b.app_id	
	where t.status='{zt}' and t.sscj='{cjmc}' and DATE_FORMAT(t.bizdate,'%Y%m')='{dy}'
	group by t.odps_project_name,
	t.node_def_id,
	t.node_name) a,(select @num :=0) c;
    """
    def get_b3302_sbrwqk(self):
        return self.__b3302_sbrwqk.format(cjmc="镜像层",dy=self.ny,zt=5)

    # 表3303 未运行实例统计  直接用上面的sql
    def get_b3303_wyxrwqk(self):
        return self.__b3302_sbrwqk.format(cjmc="镜像层",dy=self.ny,zt=1)

    # ----------------------------------------- 基础层 ----------------------------------------- #
    # 表4101 基础层的生产项目空间-由于没有维护表所以暂时先这样
    __b4101_jccscxmkj_info="""
    select *
    from
    (
    select 1 as xh, 'SC_JC_GSZJ' as xmmc, '生产_基础_国税总局' as xmzwmc union all
    select 2 as xh, 'SC_JC_GSAQ' as xmmc, '生产_基础_个税安全' as xmzwmc union all
    select 3 as xh, 'SC_JC_SXSW' as xmmc, '生产_基础_山西税务' as xmzwmc union all
    select 4 as xh, 'SC_JC_DLSW' as xmmc, '生产_基础_大连税务' as xmzwmc union all
    select 5 as xh, 'SC_JC_YNSW' as xmmc, '生产_基础_云南税务' as xmzwmc union all
    select 6 as xh, 'SC_JC_QHSW' as xmmc, '生产_基础_青海税务' as xmzwmc union all
    select 7 as xh, 'SC_JC_LNSW' as xmmc, '生产_基础_辽宁税务' as xmzwmc union all
    select 8 as xh, 'SC_JC_NXSW' as xmmc, '生产_基础_宁夏税务' as xmzwmc union all
    select 9 as xh, 'SC_JC_XJSW' as xmmc, '生产_基础_新疆税务' as xmzwmc union all
    select 10 as xh, 'SC_JC_CYJJQ' as xmmc, '生产_基础_川渝经济圈' as xmzwmc
    )
    mx
    """
    def get_b4101_jccscxmkj_info(self):
        return self.__b4101_jccscxmkj_info

    # 表4102 基础层任务统计
    def get_b4102_jccrwtj(self):
        return self.__b3101_scrwsltj.format(cjmc="基础层",dy=self.ny,sy=self.pre_ny)

    # 表4103 基础层新增任务统计
    def get_b4103_jjcxzrwtj(self):
        return self.__b3102_scxzrw.format(cjmc="基础层",dy=self.ny)

    # 表4201 调度类型统计任务
    def get_b4201_ddlxtj(self):
        return self.__b3201_ddlxtjrws.format(cjmc="基础层",dy=self.ny)

    # 表4202 正常任务按任务类型统计
    def get_b4202_zcrwalxtj(self):
        return self.__b3202_zcrwalxtj.format(cjmc="基础层",dy=self.ny)

    # 表4301 任务运行状态统计
    def get_b4301_rwyxzttj(self):
        return self._b3301_rwyxzttj.format(cjmc="基础层",dy=self.ny)

    # 表4302 未运行任务明细
    def get_b4302_wyxrwmx(self):
        return self.__b3302_sbrwqk.format(cjmc="基础层",dy=self.ny,zt=1)

    # 表4303 失败任务明细
    def get_b4303_sbrwmx(self):
        return self.__b3302_sbrwqk.format(cjmc="基础层",dy=self.ny,zt=5)

    # 表4401 消耗资源最高
    __b4401_xhzyzg="""
    select CAST(@num :=@num+1 AS char) xh,upper(project_name) xmmc,
    '' as rwmc,
    cost_cpu,
    start_time,
    end_time,
    TIMEDIFF(end_time,start_time) as yxsc
    from zlzyb_zytop10,(select @num :=0) a
    where sscj='{cjmc}' and left(ds,6)='{dy}';
    """
    def get_b4401_xhzyzg(self):
        return self.__b4401_xhzyzg.format(cjmc="基础层",dy=self.ny)

    # 表4501 任务运行时长top
    __b4501_rwyxsc="""
    select CAST(@num :=@num+1 AS char) as xh,
	project_name
    ,node_name
    ,start_time
    ,finish_time
    ,yxsc
    ,bizdate
    from zlzyb_yxsctop10,(select @num :=0) a
    where tj_ny='{dy}' and sscj='{cjmc}';
    """
    def get_b4501_rwyxsc(self):
        return self.__b4501_rwyxsc.format(cjmc="基础层",dy=self.ny)

    # ----------------------------------------- 中间层 ----------------------------------------- #
    # 表5101 的生产项目空间 - 由于没有维护表这里暂时作为固定内容

    __b5101_jccscxmkj_info = """
       select *
       from
       (
       select 1 as xh, 'SC_ZJ_GSZJ' as xmmc, '生产_中间_国税总局' as xmzwmc union all
       select 2 as xh, 'SC_ZJ_GSAQ' as xmmc, '生产_中间_个税安全' as xmzwmc union all
       select 3 as xh, 'SC_ZJ_SXSW' as xmmc, '生产_中间_山西税务' as xmzwmc union all
       select 4 as xh, 'SC_ZJ_DLSW' as xmmc, '生产_中间_大连税务' as xmzwmc union all
       select 5 as xh, 'SC_ZJ_YNSW' as xmmc, '生产_中间_云南税务' as xmzwmc union all
       select 6 as xh, 'SC_ZJ_QHSW' as xmmc, '生产_中间_青海税务' as xmzwmc union all
       select 7 as xh, 'SC_ZJ_LNSW' as xmmc, '生产_中间_辽宁税务' as xmzwmc union all
       select 8 as xh, 'SC_ZJ_NXSW' as xmmc, '生产_中间_宁夏税务' as xmzwmc union all
       select 9 as xh, 'SC_ZJ_XJSW' as xmmc, '生产_中间_新疆税务' as xmzwmc union all
       select 10 as xh, 'SC_ZJ_CYJJQ' as xmmc, '生产_中间_川渝经济圈' as xmzwmc
       )
       mx
       """

    def get_b5101_jccscxmkj_info(self):
        return self.__b5101_jccscxmkj_info

    # 表5102 中间层任务统计
    def get_b5102_jccrwtj(self):
        return self.__b3101_scrwsltj.format(cjmc="中间层",dy=self.ny,sy=self.pre_ny)

    # 表5103 中间层新增任务统计
    def get_b5103_jjcxzrwtj(self):
        return self.__b3102_scxzrw.format(cjmc="中间层",dy=self.ny)

    # 表5201 调度类型统计任务
    def get_b5201_ddlxtj(self):
        return self.__b3201_ddlxtjrws.format(cjmc="中间层",dy=self.ny)

    # 表5202 正常任务按任务类型统计
    def get_b5202_zcrwalxtj(self):
        return self.__b3202_zcrwalxtj.format(cjmc="中间层",dy=self.ny)

    # 表5301 任务运行状态统计
    def get_b5301_rwyxzttj(self):
        return self._b3301_rwyxzttj.format(cjmc="中间层",dy=self.ny)

    # 表5302 未运行任务明细
    def get_b5302_wyxrwmx(self):
        return self.__b3302_sbrwqk.format(cjmc="中间层",dy=self.ny,zt=1)

    # 表5303 失败任务明细
    def get_b5303_sbrwmx(self):
        return self.__b3302_sbrwqk.format(cjmc="中间层", dy=self.ny, zt=5)

    # 表5401 消耗资源最高
    def get_b5401_xhzyzg(self):
        return self.__b4401_xhzyzg.format(cjmc="中间层",dy=self.ny)

    # 表5501 任务运行时长top
    def get_b5501_rwyxsc(self):
        return self.__b4501_rwyxsc.format(cjmc="中间层",dy=self.ny)

    # ----------------------------------------- 模型层 ----------------------------------------- #
    # 表6101 模型层的生产项目空间任务统计 需要核实模板到底是几个表，模板是两个，当时为啥写三个sql
    def get_b6101_jccscxmkj_info(self):
        return self.__b3101_scrwsltj.format(cjmc="模型层",dy=self.ny,sy=self.pre_ny)

    # 表6102 模型层新增任务统计
    def get_b6102_jccrwtj(self):
        return self.__b3102_scxzrw.format(cjmc="模型层",dy=self.ny)

    # 表6103 模型层新增任务统计
    def get_b6103_jjcxzrwtj(self):
        return self.__b3102_scxzrw.format(cjmc="模型层",dy=self.ny)

    # 表6201 调度类型统计任务
    def get_b6201_ddlxtj(self):
        return self.__b3201_ddlxtjrws.format(cjmc="模型层",dy=self.ny)

    # 表6202 正常任务按任务类型统计
    def get_b6202_zcrwalxtj(self):
        return self.__b3202_zcrwalxtj.format(cjmc="模型层",dy=self.ny)

    # 表6301 任务运行状态统计
    def get_b6301_rwyxzttj(self):
        return self._b3301_rwyxzttj.format(cjmc="模型层",dy=self.ny)

    # 表6302 未运行任务明细
    def get_b6302_wyxrwmx(self):
        return self.__b3302_sbrwqk.format(cjmc="模型层",dy=self.ny,zt=1)

    # 表6302 失败任务明细
    def get_b6302_sbrwmx(self):
        return self.__b3302_sbrwqk.format(cjmc="模型层",dy=self.ny,zt=5)

    # 表6401 消耗资源最高
    def get_b6401_xhzyzg(self):
        return self.__b4401_xhzyzg.format(cjmc="模型层",dy=self.ny)

    # 表6501 任务运行时长top
    def get_b6501_rwyxsc(self):
        return self.__b4501_rwyxsc.format(cjmc="模型层",dy=self.ny)