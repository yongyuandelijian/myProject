#!/bin/bash
# author:aaa
# 从分发库直接抽取到sc_jc_sjsykj_ynsw  输入   sc_jc_sjsykj_ynsw.hx_wbcx_yn_sjksh_sssrygdpycyzjz
# 参数：bizdate 业务分区，dwmc 单位代码 targettable 目标表名称
# 周期: 按季抽取
################################################################################
# 云端准备
tdir='/home/admin'
if [ -d "${tdir}/chkend" ];then
 echo "Check client successed"
else
 mkdir -p "${tdir}/client";
 if [[ $? -ne 0 ]];then 
    while true 
    do 
      if [ -d "${tdir}/chkend" ];then break;else echo "check ...";sleep 30;fi
    done
   else
    wget -P ${tdir} 1111 && cd ${tdir} && tar -zxvf client.tar.gz -C ${tdir}
    if [[ $? -ne 0 ]];then echo "tar failed";rm -rf ${tdir}/client;else mkdir "${tdir}/chkend";fi
 fi
fi

# 目录准备
mydir=`pwd`
json_dir="${mydir}/${bizdate}/${dwmc}/json"
log_dir="${mydir}/${bizdate}/${dwmc}/log"
if [ ! -d json_dir ]; then mkdir -p "${json_dir}"; fi;
if [ ! -d log_dir ]; then mkdir -p "${log_dir}"; fi;
#####################################################################################################
# 参数准备

# 传入参数
bizdate=$1
dwmc=$2
targettable=$3
owner="HX_WBCX"
dwmc=`echo ${dwmc}|tr 'a-z' 'A-Z'`
targettable=`echo ${targettable}|tr 'a-z' 'A-Z'`

# 计算参数
scriptPath="`pwd`"
sykj_project=`echo "SC_JC_SJSYKJ_${dwmc}" |sed 's/ST$/SW/g'`
sourceTable=$(echo ${targettable}|tr 'a-z' 'A-Z'|sed 's/HX_WBCX_//g')  # 去掉用户名获取原表

# 固定参数
odpscmd="/home/admin/client/odps/bin/odpscmd --endpoint=1111 -u 2222 -p 3333 
--project=${sykj_project}"
ossutil='/home/admin/client/ossutil'
endpoint='1111'
accessid='2222'
accesskey='333'
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
if   [ "$db" = "rcount" ]; then
jdbc="-h99.13.220.242 -P3306 -urcount -prcount -D rcount"
#sc_sjzlpt（v3）配置
elif [ "$db" = "sjzlpt" ];then
jdbc="-h99.13.222.87 -P3306 -usc_dsjsjzlpt -psjzlpt_css12st27 -D sc_sjzlpt"
fi
sdata=`mysql $jdbc -N -e "${sql}"`
if [[ $? -ne 0 ]];then echo "select rds error";exit 1;fi
echo $sdata
}


# 获取数据源连接方式，云南实际测试 ffk_datasource_conf 这个表的配置是正确的 datasource_conf表的配置无法登陆
sql="select concat(db,'|',jdbc,'|',user,'|',pass) from ffk_datasource_conf where dwmc = '${dwmc}';"
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
  from sys.dba_tab_cols t1
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
from sys.dba_tab_columns t 
where t.owner = upper('${owner}')
and t.table_name=upper('${sourceTable}');
quit;
END`

# str="${source_tab} >>> select t.column_name from sys.dba_tab_columns t where t.owner = upper('${owner}') and t.table_name=upper('${source_tab}');"
# echo ${str}
source_col=`echo ${source_col}|sed 's/^/"/g'|sed 's/ /","/g'|awk '{printf $0}'|tr '[a-z]' '[A-Z]'`
source_col="${source_col}\""
# 处理时间类型
date_col=`${odpscmd} -e "desc ${sykj_project}.${targettable};"|grep 'datetime' | awk '{print $2}'`
for i in `echo ${date_col}` ;
do
i=`echo ${i}|tr 'a-z' 'A-Z'`
echo "当前正在处理的是${i}"
source_col=`echo ${source_col}|sed 's/"'"${i}"'"/"case when '${i}' <to_date(00010101,yyyymmdd) then to_date(00010101,yyyymmdd) when '${i}' >to_date(99991231235959,yyyymmddhh24miss) then null else '${i}' end"/g'`
done
echo "源端表列：${source_col}"
if [[ ! ${source_col} ]];
then
echo "${sourceTable} 从分发库获取列失败 !!!";
exit -1
fi;

# 获取基础层列
odps_col=`${odpscmd} -e "desc ${sykj_project}.${targettable};"|grep -E 'bigint|string|boolean|double|datetime|decimal' | awk '{print $2}' | awk '{printf $0","}'| tr '[a-z]' '[A-Z]'`; 
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
          \"column\":[${source_col},
            \"sysdate\"
          ],
          \"connection\":[
            {
              \"jdbcUrl\":[
                \"jdbc:oracle:thin:@${jdbc}\"
              ],
              \"table\":[
                \"${owner}.${sourceTable}\"
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
           \"column\":[${odps_col},
              \"yptetl_sj\"
           ],
           \"odpsServer\":\"${odpsServer}\",
           \"partition\":\"rfq=${bizdate}\",
           \"project\":\"${sykj_project}\",
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
echo ${json} >"${json_dir}/${sykj_project}${targettable}.json"
#列的字符均被定义为大写，所有的关键字在这里做转换

sed -i "s/99991231235959,yyyymmddhh24miss/'99991231235959','yyyymmddhh24miss'/g" ${json_dir}/${sykj_project}${targettable}.json

python /home/admin/datax/bin/datax.py ${json_dir}/${sykj_project}${targettable}.json>${log_dir}/${sykj_project}${targettable}.log 2>&1 & 


 
exit 0