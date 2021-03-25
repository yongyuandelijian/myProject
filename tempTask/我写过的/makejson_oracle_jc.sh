#!/bin/bash
# author:aaa
# 从分发库直接抽取到sc_jc_gszj
# 参数：bizdate 业务分区， dwmc  单位代码 targettable 目标表名称  owner 用户名称
################################################################################


#####################################################################################################
# 参数准备
odpsServer="http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api"     #
tunnelServer="http://dt.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn"            #
odpsaccessId="yXKpKuN0xKF5MLpK"                                                #
odpsaccessKey="1glCWzC8XkTT3BSpoY9NkYMibQslxB"   
# 传入参数
bizdate=$1
dwmc=$2
targettable=$3
owner=$4
dwmc=`echo ${dwmc}|tr 'a-z' 'A-Z'`
targettable=`echo ${targettable}|tr 'a-z' 'A-Z'`


# 计算参数
tar_project='SC_JC_GSZJ'
sourceTable=$(echo ${targettable}|tr 'a-z' 'A-Z'|sed 's/'${owner}'_//g')  # 去掉用户名获取原表


# 目录准备
mydir=`pwd`
json_dir="${mydir}/${bizdate}/${dwmc}/json"
log_dir="${mydir}/${bizdate}/${dwmc}/log"
if [ ! -d json_dir ]; then mkdir -p "${json_dir}"; fi;
if [ ! -d log_dir ]; then mkdir -p "${log_dir}"; fi;

# 固定参数
odpscmd="/home/admin/client/odps/bin/odpscmd --endpoint=http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api -u yXKpKuN0xKF5MLpK -p 1glCWzC8XkTT3BSpoY9NkYMibQslxB 
--project=${tar_project}"
ossutil='/home/admin/client/ossutil'
endpoint='oss-cn-foshan-lhc-d01-a.alicloud.its.tax.cn'
accessid='yXKpKuN0xKF5MLpK'
accesskey='1glCWzC8XkTT3BSpoY9NkYMibQslxB'
${ossutil} config -e ${endpoint} -i ${accessid} -k ${accesskey}

# sqlplus环境变量
export ORACLE_HOME=/home/admin/client/oracle
export LD_LIBRARY_PATH=/home/admin/client/oracle/lib
export PATH=$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH


#定义mysql函数
mysqlcmd()
{
db="$1"
sql="$2"
#rcount（v3）配置
jdbc="-h99.13.220.242 -P3306 -urcount -prcount -D rcount"

sdata=`mysql $jdbc -N -e "${sql}"`
if [[ $? -ne 0 ]];then echo "select rds error";exit 1;fi
echo $sdata
}

# 获取数据源连接方式，云南实际测试 ffk_datasource_conf 这个表的配置是正确的 datasource_conf表的配置无法登陆
sql="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where  dwmc='GSZJ' and sysname='J1_FWSK';"
echo ${sql}
echo `date "+%Y-%m-%d %H:%M:%S"`
mysqlcmd "rcount" "${sql}"
db=`echo ${sdata}  |awk -F "|" '{print $1}'`
jdbc=`echo ${sdata}|awk -F "|" '{print $2}'`
user=`echo ${sdata}|awk -F "|" '{print $3}'`
pass=`echo ${sdata}|awk -F "|" '{print $4}'`

# 获取表在oracle中的用户名和表名称（ 结果样式：HX_ZS_ZS_XHXX|HX_ZS|ZS_XHXX|| ）
source_tab=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set linesize 30000
set verify off
set echo off
select t1.owner || '_' || t1.TABLE_NAME || '|' || t1.owner || '|' ||
	   t1.TABLE_NAME || '||'
  from all_tab_cols t1
 where t1.owner || '_' || t1.TABLE_NAME = upper('${targettable}')
 group by t1.owner || '_' || t1.TABLE_NAME || '|' || t1.owner || '|' ||
		  t1.TABLE_NAME || '||';
quit;
END`

if [ $? -ne 0 ] || [[ ! ${source_tab} ]];
then
echo "${sourceTable} 从分发库中没有找到 !!!";
exit -1
fi;

# 获取列名称
source_col=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
select t.column_name
from all_tab_columns t 
where t.owner = upper('${owner}')
and t.table_name=upper('${sourceTable}');
quit;
END`

echo "owner是：${owner} 表名称是：${sourceTable}"
# str="${source_tab} >>> select t.column_name from sys.dba_tab_columns t where t.owner = upper('${owner}') and t.table_name=upper('${source_tab}');"
# echo ${str}
source_col=`echo ${source_col}|sed 's/^/"/g'|sed 's/ /","/g'|awk '{printf $0}'|tr '[a-z]' '[A-Z]'`
source_col="${source_col}\""
# 处理时间类型
# # # date_col=`${odpscmd} -e "desc ${tar_project}.${targettable};"|grep 'datetime' | awk '{print $2}'`
# # # for i in `echo ${date_col}` ;
# # # do
# # # i=`echo ${i}|tr 'a-z' 'A-Z'`
# # # echo "当前正在处理的是${i}"
# # # source_col=`echo ${source_col}|sed 's/"'"${i}"'"/"case when '${i}' <to_date(00010101,yyyymmdd) then to_date(00010101,yyyymmdd) when '${i}' >to_date(99991231235959,yyyymmddhh24miss) then null else '${i}' end"/g'`
# # # done
echo "源端表列：${source_col}"
if [[ ! ${source_col} ]];
then
echo "${sourceTable} 从分发库获取列失败 !!!";
exit -1
fi;

# 获取基础层列
odps_col=`${odpscmd} -e "desc ${tar_project}.${targettable};"|grep -E 'bigint|string|boolean|double|datetime|decimal' | awk '{print $2}'| awk '{printf $0","}'| tr '[a-z]' '[A-Z]'`; 
odps_col=`echo ${odps_col}|sed 's/^/"/g'|awk '{printf $0}'|sed 's/,/","/g'|tr '[a-z]' '[A-Z]'|sed 's/.$//g'`
odps_col=${odps_col%?}
echo "目标表列：${odps_col}"

# 存储获取结果
echo "${source_tab}${source_col} odps column is ：${odps_col}" >${mydir}\all.config


################################################################################
#JSON 配置
################################################################################ 
speed="10"
truncate="true"

#################################生成一个同步主键到 temp_${table_name}_$bizdate 表的json 并执行抽取 ###############################################

json="{
\"job\": {
  \"content\":[
    {
      \"reader\":{
        \"name\":\"${db}\",
        \"parameter\":{
          \"column\":[
		  ${source_col},
		  \" sysdate \" 
          ],
          \"connection\":[
            {
              \"jdbcUrl\":[
                \"jdbc:oracle:thin:@${jdbc}\"
              ],
              \"table\":[
                \"${sourceTable}\"
              ]
            }
          ],
          \"fetchSize\":1024,
          \"password\":\"${pass}\",
          \"splitPk\":\"\",
          \"username\":\"${user}\",
          \"where\":\"\"
        }
      },
       \"writer\":{
         \"name\":\"odpswriter\",
         \"parameter\":{
           \"accessId\":\"${odpsaccessId}\",
           \"accessKey\":\"${odpsaccessKey}\",
           \"column\":[
		   ${odps_col},
           ],
           \"odpsServer\":\"${odpsServer}\",
           \"partition\":\"rfq=${bizdate},sjlybz='GSZJ'\",
           \"project\":\"${tar_project}\",
           \"table\":\"${targettable}\",
           \"truncate\":${truncate},
           \"tunnelServer\":\"${tunnelServer}\"
         }
       }
    }
  ],
  \"setting\":{
    \"errorLimit\":{
    \"record\":0
    },
    \"speed\":{
      \"channel\":${speed}
    }
  }
 }
}"

odps_col=`echo ${odps_col}|sed  's/,"RFQ","SJLYBZ",//g'`

echo ${json}|sed 's/,"RFQ"//g'|sed 's/,"SJLYBZ",//g' >${json_dir}/${tar_project}${targettable}.json
#列的字符均被定义为大写，所有的关键字在这里做转换

# python /home/admin/datax/bin/datax.py ${json_dir}/${tar_project}${targettable}.json>${log_dir}/${tar_project}${targettable}.log 2>&1 & 

exit 0





# 附带脚本

# for tablename in `cat table.list|tr [a-z] [A-Z]`
# do
# echo "sh makejson_oracle_jc.sh 20200909 GSZJ ${tablename} J1_FWSK >${tablename}.ms;" >>run.sh;
# done
# 
# 
# for jsonname in `ls 20200909/GSZJ/json/`;do nohup python /home/admin/datax3/bin/datax.py --jvm="-Xms2g -Xmx8g" 20200909/GSZJ/json/${jsonname} > 20200909/GSZJ/log/${jsonname}.log 2>&1 & done
# 
# python /home/admin/datax3/bin/datax.py --jvm="-Xms2g -Xmx8g" 20200908/GSZJ/json/SC_JC_GSZJJ1_FWSK_DM_CPY_SB.json > J1_FWSK_DM_CPY_SPBM_HG.log 2>&1
# 
# $for dk in `ps -ef |grep datax |awk '{print $2}'`;do kill ${dk}; done;
# 
# 
# 
# for tablename in `cat table.list`
# do
# tarname=`echo ${tablename}|sed 's/$/_ZL/g'`;
# echo "alter table sc_jx_gszj.${tablename} rename to ${tarname};";
# done