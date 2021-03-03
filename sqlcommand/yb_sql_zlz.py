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

    # 表2.1 第一个 层级项目数量
    __b2101_cjxmsl="""
    select xx.cjxh,xx.cjmc,ifnull(mx.xmsl,0) xmsl,0 xmxzsl
    from zlzyb_projectlevel_info xx
    left join 
    (select sscj,count(DISTINCT odps_project_name) xmsl 
    from zlzyb_odpsproject_info 
    where left(create_time,7)<='{nf}-{yf}'  
    group by sscj
    union ALL
    select '合计' sscj,count(DISTINCT odps_project_name) xmsl 
    from zlzyb_odpsproject_info 
    where left(create_time,7)<='{nf}-{yf}'  
    ) mx on xx.cjmc=mx.sscj
    order by xx.cjxh;
    """
    def get_b2101_cjxmsl(self):
        return self.__b2101_cjxmsl.format(nf=self.nf,yf=self.yf)


    # 表2.1 第二个表 重点项目任务数量分组统计
    __b2102_zdxmrwtj="""
    select xx.cjxh,xx.cjmc,ifnull(mx.xmsl,0) xmsl,ifnull(mx.rwsl,0) rwsl,0 hbxz
    from zlzyb_projectlevel_info xx
    left join 
    (SELECT
        b.sscj,
        count(DISTINCT odps_project_name) xmsl ,
        count(DISTINCT a.node_def_id) AS rwsl
    FROM
        zlzyb_odpsproject_info b
    LEFT JOIN (
        SELECT
            app_id,
            node_def_id
        FROM
            phoenix_node_def
        WHERE
            node_def_id NOT IN (
                SELECT
                    node_def_id
                FROM
                    jxclsrw_20201222
            )
        AND left(create_time,7)<='{nf}-{yf}'
    ) a ON a.app_id = b.app_id
    WHERE
        b.zdxm = 'Y'
    AND left(b.create_time,7)<='{nf}-{yf}'
    GROUP BY
        b.sscj
    union ALL
    SELECT
        '合计' sscj,
        count(DISTINCT odps_project_name) xmsl ,
        count(DISTINCT a.node_def_id) AS rwsl
    FROM
        zlzyb_odpsproject_info b
    LEFT JOIN (
        SELECT
            app_id,
            node_def_id
        FROM
            phoenix_node_def
        WHERE
            node_def_id NOT IN (
                SELECT
                    node_def_id
                FROM
                    jxclsrw_20201222
            )
        AND left(create_time,7)<='{nf}-{yf}'
    ) a ON a.app_id = b.app_id
    WHERE
        b.zdxm = 'Y'
    AND left(b.create_time,7)<='{nf}-{yf}'
    
    ) mx on xx.cjmc=mx.sscj
    order by xx.cjxh;
    """

    def get_b2102_zdxmrwtj(self):
        return self.__b2102_zdxmrwtj.format(nf=self.nf,yf=self.yf)

    # 表2.1 第二个表 重点项目新增任务数量分组统计
    __b2103_zdxmxzrwtj = """
    select xx.cjxh,xx.cjmc,ifnull(mx.rwsl,0) rwsl,0 hbxz
    from zlzyb_projectlevel_info xx
    left join 
    (SELECT
        b.sscj,
        count(DISTINCT odps_project_name) xmsl ,
        count(DISTINCT a.node_def_id) AS rwsl
    FROM
        zlzyb_odpsproject_info b
    LEFT JOIN (
        SELECT
            app_id,
            node_def_id
        FROM
            phoenix_node_def
        WHERE
            node_def_id NOT IN (
                SELECT
                    node_def_id
                FROM
                    jxclsrw_20201222
            )
        AND left(create_time,7)='{nf}-{yf}'
    ) a ON a.app_id = b.app_id
    WHERE
        b.zdxm = 'Y'
    AND left(b.create_time,7)<='{nf}-{yf}'
    GROUP BY
        b.sscj
    union ALL
    SELECT
        '合计' sscj,
        count(DISTINCT odps_project_name) xmsl ,
        count(DISTINCT a.node_def_id) AS rwsl
    FROM
        zlzyb_odpsproject_info b
    LEFT JOIN (
        SELECT
            app_id,
            node_def_id
        FROM
            phoenix_node_def
        WHERE
            node_def_id NOT IN (
                SELECT
                    node_def_id
                FROM
                    jxclsrw_20201222
            )
        AND left(create_time,7)='{nf}-{yf}'
    ) a ON a.app_id = b.app_id
    WHERE
        b.zdxm = 'Y'
    AND left(b.create_time,7)<='{nf}-{yf}'

    ) mx on xx.cjmc=mx.sscj
    order by xx.cjxh;
    """

    def get_b2103_zdxmxzrwtj(self):
        return self.__b2103_zdxmxzrwtj.format(nf=self.nf, yf=self.yf)

    ### 表格22-01 层级任务数量分调度类型统计
    __b2201_fdtlxtj="""
    select xx.cjxh,xx.cjmc,mx.zs,mx.zc,mx.sd,mx.zt,mx.kp FROM
	zlzyb_projectlevel_info xx
    left join 
    (SELECT
        b.sscj,
        ifnull(sum(rwsl),0) zs,
        ifnull(sum(case when node_type=0 then rwsl end),0) zc,
        ifnull(sum(case when node_type=1 then rwsl end),0) sd,
        ifnull(sum(case when node_type=2 then rwsl end),0) zt,
        ifnull(sum(case when node_type=3 then rwsl end),0) kp       
    FROM
        zlzyb_odpsproject_info b
    LEFT JOIN (
        SELECT
            app_id,
            node_type,
            count(DISTINCT node_def_id) AS rwsl
        FROM
            phoenix_node_def
        WHERE
            node_def_id NOT IN (
                SELECT
                    node_def_id
                FROM
                    jxclsrw_20201222
            )
        AND left(create_time,7)<='{nf}-{yf}'
        GROUP BY
            app_id,
            node_type
    ) a ON a.app_id = b.app_id
    WHERE
        zdxm = 'Y'
    AND left(create_time,7)<='{nf}-{yf}'
    GROUP BY
        b.sscj
    union ALL
    SELECT
        '合计' sscj,
        ifnull(sum(rwsl),'0') zs,
        ifnull(sum(case when node_type=0 then rwsl end),'0') zc,
        ifnull(sum(case when node_type=1 then rwsl end),'0') sd,
        ifnull(sum(case when node_type=2 then rwsl end),'0') zt,
        ifnull(sum(case when node_type=3 then rwsl end),'0') kp
        
    FROM
        zlzyb_odpsproject_info b
    LEFT JOIN (
        SELECT
            app_id,
            node_type,
            count(DISTINCT node_def_id) AS rwsl
        FROM
            phoenix_node_def
        WHERE
            node_def_id NOT IN (
                SELECT
                    node_def_id
                FROM
                    jxclsrw_20201222
            )
        AND left(create_time,7)<='{nf}-{yf}'
        GROUP BY
            app_id,
            node_type
    ) a ON a.app_id = b.app_id
    WHERE
        zdxm = 'Y'
    AND left(create_time,7)<='{nf}-{yf}'
    ) mx on xx.cjmc=mx.sscj
    order by xx.cjxh;
    """
    def get_b2201_fdtlxtj(self):
        return self.__b2201_fdtlxtj.format(nf=self.nf,yf=self.yf)

    ### 表格23-01 正常调度任务的运行状态分数据层统计
    __b2301_zcrwfyxzttj="""
    select xx.cjxh,xx.cjmc,mx.zs,mx.wyx,mx.yxz,mx.yxsb,mx.yxcg,mx.xz
    FROM zlzyb_projectlevel_info xx
    left join (
        select cj sscj,
        sum(inst_num) zs,
        ifnull(sum(case when status=1 then inst_num end),0) wyx,
        ifnull(sum(case when status=4 then inst_num end),0) yxz,
        ifnull(sum(case when status=5 then inst_num end),0) yxsb,
        ifnull(sum(case when status=6 then inst_num end),0) yxcg,
        0 xz
        from  zlzyb_instance_tjb 
        where tj_ny='{ny}'
        group by cj
        union ALL
        select '合计' sscj,
        sum(inst_num) zs,
        ifnull(sum(case when status=1 then inst_num end),0) wyx,
        ifnull(sum(case when status=4 then inst_num end),0) yxz,
        ifnull(sum(case when status=5 then inst_num end),0) yxsb,
        ifnull(sum(case when status=6 then inst_num end),0) yxcg,
        0 xz
        from  zlzyb_instance_tjb 
        where tj_ny='{ny}'
    ) mx on xx.cjmc=mx.sscj
    order by xx.cjxh;
    """
    def get_b2301_zcrwfyxzttj(self):
        return self.__b2301_zcrwfyxzttj.format(ny=self.ny)