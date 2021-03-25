#!/bin/bash
# 功能：从分发库获取指定单位表的全量主键到PRI表
# 参数：1 bizdate 日分区 2 dwmc 单位代码 3 基础层表名称 （ZJ_HCP_HCP_PJJG_YJ）
# author：aaa
# date: 20201023
# 用法：nohup sh getallpk_hcp.sh 20201022 SXST PRI_ZJ_HCP_HCP_PJJG_YJ >20201022.log 2>&1 &
###################################################################################################
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
    wget -P ${tdir} 11111111111111 && cd ${tdir} && tar -zxvf client.tar.gz -C ${tdir}
    if [[ $? -ne 0 ]];then echo "tar failed";rm -rf ${tdir}/client;else mkdir "${tdir}/chkend";fi
 fi
fi
###################################################################################################

# 目录准备
mydir=`pwd`
# 传入参数
bizdate=$1
dwmc=$2
jobname=$3

# 如果参数个数不匹配则提示校验，防止带入造成较大问题
if [ $# -ne 3 ];then echo "要求的参数个数是bizdate和dwmc以及表名共3个，当前提供的参数是$#个，分别是$*请检查核对！！！"; exit -1; fi;

#更改标准
jobname=`echo ${jobname}|tr 'a-z' 'A-Z'`
dwmc=`echo ${dwmc}|tr 'a-z' 'A-Z'`
project="SC_JX_${dwmc}"
targettable=`echo ${jobname}`
sourceTable=`echo ${jobname}|tr 'a-z' 'A-Z'|sed 's/^PRI_ZJ_HCP_//g'`    
owner="ZJ_HCP"
echo "jobname ${jobname} owner ${owner} sourceTable ${sourceTable} targettable ${targettable}"
allpk_json="${mydir}/${bizdate}/${dwmc}/allpk_json"
allpk_log="${mydir}/${bizdate}/${dwmc}/allpk_log"
if [ ! -d ${allpk_json} ]; then mkdir -p "${allpk_json}"; fi;
if [ ! -d ${allpk_log} ]; then mkdir -p "${allpk_log}"; fi;
# 参数准备


# sqlplus环境变量
export ORACLE_HOME=/home/admin/client/oracle
export LD_LIBRARY_PATH=/home/admin/client/oracle/lib
export PATH=$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH
export NLS_LANG="AMERICAN_AMERICA.UTF8"


#定义mysql函数
mysqlcmd()
{
db="$1"
sql="$2"
#rcount（v3）配置
if   [ "$db" = "rcount" ]; then
jdbc=
#sc_sjzlpt（v3）配置
elif [ "$db" = "sjzlpt" ];then
jdbc=
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

odps_tablename="LS_ZJ_HCP_${sourceTable}"
# 从rcount中获取列信息并对datetime类型的列进行处理
sql="select concat(project, '|', odps_tablename, '|', oracle_owner, '|', oracle_tablename, '|', IFNULL(splitPk,''))
     from column_conf
     where dwmc = '${dwmc}' and odps_tablename = '${odps_tablename}';"
echo ${sql}
echo `date "+%Y-%m-%d %H:%M:%S"`
list=`mysqlcmd "rcount" "${sql}"`
echo "获取到表的配置文件是:${list}"
if   [[ ! $list ]];then "配置文件中没有这个表";exit 1;fi
stable=`echo $list|awk -F '|' '{print $3"."$4}'`
sspk=`echo $list|awk -F '|' '{print $5}'`
#获取字段
owner=`echo $list|awk -F '|' '{print $3}'`
table_name=`echo $list|awk -F '|' '{print $4}'`

## odps 配置
project=`echo $list|awk -F '|' '{print $1}'` 
partition=${bizdate}
truncate="true"
sstable=`echo $list|awk -F '|' '{print $3"."$4}'`


#JSON 参数
speed="4"
################################################################################
json="{
\"job\": {
  \"content\":[
    {
      \"reader\":{
        \"name\":\"${db}\",
        \"parameter\":{
          \"column\":[
		  \"${sspk}\"
          ],
          \"connection\":[
            {
              \"jdbcUrl\":[
                \"jdbc:oracle:thin:@${jdbc}\"
              ],
              \"table\":[
                \"${stable}\"
              ]
            }
          ],
          \"fetchSize\":1024,
          \"password\":\"${pass}\",
          \"splitPk\":\"\",
          \"username\":\"${user}\",
          \"where\":\"${swhere}\"
        }
      },
       \"writer\":{
         \"name\":\"odpswriter\",
         \"parameter\":{
           \"accessId\":\"${odpsaccessId}\",
           \"accessKey\":\"${odpsaccessKey}\",
           \"column\":[
		   \"${sspk}\"
           ],
           \"odpsServer\":\"${odpsServer}\",
           \"partition\":\"rfq=${partition}\",
           \"project\":\"${project}\",
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
#列的字符均被定义为大写，所有的关键字在这里做转换
echo "${json}" >&1 |tee -a ${allpk_json}/${project}${jobname}.json

python /home/admin/datax3/bin/datax.py --jvm="-Xms1g -Xmx4g" ${allpk_json}/${project}${jobname}.json
if [[ $? -ne 0 ]];then echo "get all primarykey datax error";exit 1;fi
exit 0