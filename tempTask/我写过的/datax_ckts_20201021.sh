#!/bin/bash
#################################################################################
# ScriptName: datax_ckts.sh
# Author: lvbo
# Create Date: 2018-10-20 18:31
# Modify Author: wuyuezhen
# Modify Date: 2018-12-03 10:22
# Function: 
# Parameter:  $1 bizdate $2 GSZJ $3 jobname $4 5
#################################################################################
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
    wget -P ${tdir} 127.0.0.1 && cd ${tdir} && tar -zxvf client.tar.gz -C ${tdir}
    if [[ $? -ne 0 ]];then echo "tar failed";rm -rf ${tdir}/client;else mkdir "${tdir}/chkend";fi
 fi
fi
# Import oracle sqlplus environment variables
export ORACLE_HOME=/home/admin/client/oracle
export LD_LIBRARY_PATH=/home/admin/client/oracle/lib
export PATH=$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH
################################################################################ 
odpsServer="11111"     #
tunnelServer="1111"            #
odpsaccessId="2222"                                                #
odpsaccessKey="3333"                                 #
################################################################################
# Define mysql function
mysqlcmd()
{
db="$1"
sql="$2"
# rcount（v3）
if   [ "$db" = "5555" ]; then
jdbc="-h127.0.0.1 -P1111 -u2222 -p3333 -D 4444"
# sc_sjzlpt（v3）
elif [ "$db" = "sjzlpt" ];then
jdbc="-h11111 -P2222 -u3333 -p4444 -D 5555"
fi
sdata=`mysql $jdbc -N -e "${sql}"`
if [[ $? -ne 0 ]];then echo "select rds error";exit 1;fi
echo $sdata
}
################################################################################
# Query datasource
sql1="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = 'GSZJ' and sysname='DB_ZG';"
echo ${sql1}
echo `date "+%Y-%m-%d %H:%M:%S"`
mysqlcmd "rcount" "${sql1}"
db=`echo ${sdata}  |awk -F "|" '{print $1}'`
jdbc=`echo ${sdata}|awk -F "|" '{print $2}'`
user=`echo ${sdata}|awk -F "|" '{print $3}'`
pass=`echo ${sdata}|awk -F "|" '{print $4}'`
#################################################################################
mydir=`pwd`
bizdate=$1
dwmc=$2
jobname=$3
num=$4
#################################################################################
curdt="`date +%Y%m%d%H%M%S`"
# Query list
sql="select concat(project, '|', odps_tablename, '|', oracle_owner, '|', oracle_tablename, '||', columns,'|', swhere,'|', splitpk)
     from column_conf
     where dwmc = 'GSZJ' and project='SC_JX_GSZJ' and odps_tablename = '${jobname}';"
echo ${sql}
echo `date "+%Y-%m-%d %H:%M:%S"`
list=`mysqlcmd "rcount" "${sql}"`
echo ${list}
if   [[ ! $list ]];then "配置文件中没有这个表";exit 1;fi
################################################################################
echo $jobname
echo $bizdate
echo $list
################################################################################ 
stable=`echo $list|awk -F '|' '{print $3"."$4}'|sed 's/+/ PARTITION (/g' |sed 's/-/)/g'`
#sspk=`echo $list|awk -F '|' '{print $5}'`

################################################################################
sselect=`echo $list|awk -F '|' '{print $6}'|tr [A-Z] [a-z]`
swhere=`echo $list|awk -F '|' '{print $7}'|sed "s/bizdate/${bizdate}/g"`
sspk=`echo $list|awk -F '|' '{print $8}'|tr [A-Z] [a-z]`	# 20201021增加，前提是使用脚本增加更新rcount主键
################################################################################
sselect=`echo -n $sselect|awk '{gsub(/,/,"\",\"",$0);print "\""$0"\""}'`
################################################################################
echo "X----------------X"
VALUE=`sqlplus -S ${user}/${pass}@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
select 0 from $stable where $owhere rownum=1;
quit;
END`
if [[ $? -ne 0 ]];then echo "select oracle error";exit 1;fi
################################################################################ 
project=`echo $list|awk -F '|' '{print $1}'`
table=`echo $list|awk -F '|' '{print $2}'`
select=`echo $list|awk -F '|' '{print $6}'|tr [a-z] [A-Z]`
select=`echo -n $select|awk '{gsub(/,/,"\",\"",$0);print "\""$0"\""}'`
################################################################################
dt=$bizdate
partition=${dt:0:6}
#yf=${dt:4:2}
#if [[ $yf -eq 01 ]];then partition=$[par-89];else partition=$[par-1];fi
truncate="true"
sstable=`echo $list|awk -F '|' '{print $3"."$4}'`
################################################################################
pdwmc=`echo $project|awk -F '_' '{print $3}'`
if [[ ${pdwmc} != ${dwmc} ]];then "column配置文件与任务参数配置中单位不匹配";exit 1;fi
################################################################################
DT=`/home/admin/client/odps/bin/odpscmd --endpoint=http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api -u yXKpKuN0xKF5MLpK -p 1glCWzC8XkTT3BSpoY9NkYMibQslxB --project=${project} -e<<END
desc ${project}.${table};
quit;
END`
if [[ ! `echo $DT |grep "Owner:"` ]];then exit 1;fi
################################################################################
DT=`echo "$DT"|sed 's/ //g'|grep "|datetime|"|awk -F "|" '{print $2}'`
echo "--$DT--"
if [[ $DT ]];then 
for i in `echo $DT|tr [A-Z] [a-z]` ;do sselect=`echo $sselect|sed 's/"'"${i}"'"/"case when '${i}' <to_date(00010101,yyyymmdd) then to_date(00010101,yyyymmdd) when '${i}' >to_date(99991231235959,yyyymmddhh24miss) then null else '${i}' end"/g'`;done
sselect=`echo -e "$sselect"|sed 's/"/\\"/g'`
fi
################################################################################
if [[ ! $num ]];then
speed="1"
else
speed="$num"
jvm="Xmx$[num/2]g"
core="
\"core\":{
  \"transport\":{
    \"channel\":{
      \"speed\":{
        \"byte\":\"-1\",
        \"record\":\"-1\"
      }
    }
  }
},
"
fi

json="{
${core}
\"job\": {
  \"content\":[
    {
      \"reader\":{
        \"name\":\"${db}\",
        \"parameter\":{
          \"column\":[${sselect},
            \" sysdate \"
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
          \"splitPk\":\"${sspk}\",
          \"username\":\"${user}\",
          \"where\":\"${swhere}\"
        }
      },
       \"writer\":{
         \"name\":\"odpswriter\",
         \"parameter\":{
           \"accessId\":\"${odpsaccessId}\",
           \"accessKey\":\"${odpsaccessKey}\",
           \"column\":[${select},
              \"yptetl_sj\"
           ],
           \"odpsServer\":\"${odpsServer}\",
           \"partition\":\"yfq=${partition}\",
           \"project\":\"${project}\",
           \"table\":\"${table}\",
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
################################################################################
echo -e "$json">${mydir}/$sstable.json
sed -i "s/00010101,yyyymmdd/'00010101','yyyymmdd'/g" ${mydir}/${sstable}.json
sed -i "s/99991231235959,yyyymmddhh24miss/'99991231235959','yyyymmddhh24miss'/g" ${mydir}/${sstable}.json
sed -i 's/"date"/"\\"date\\""/g;s/"timestamp"/"\\"timestamp\\""/g' ${mydir}/${sstable}.json
sed -i 's/ date / "\\"date\\"" /g;s/ timestamp / "\\"timestamp\\"" /g' ${mydir}/${sstable}.json
################################################################################
if [[ $num ]];then 
  if [[ ${jobname} == 'DB_ZG_B_GC_HISTORY_HXBGD' ]] || [[ ${jobname} == 'DB_ZG_B_GC_SB_MTS_TSSB_DEL' ]];then
	  python /home/admin/datax3/bin/datax.py --jvm="-Xms2g -Xmx8g" ${mydir}/${sstable}.json
	  if [[ $? -ne 0 ]];then echo "error";exit 1;fi
  else
	  python /home/admin/datax3/bin/datax.py --jvm="-Xms1g -${jvm}" ${mydir}/${sstable}.json
	  if [[ $? -ne 0 ]];then echo "error";exit 1;fi
  fi
else 
  python /home/admin/datax3/bin/datax.py ${mydir}/${sstable}.json
  if [[ $? -ne 0 ]];then echo "error";exit 1;fi
fi
####################################################################################
#获取datax运行情况
cdatax=`cat ${mydir}/*.log|grep -E "任务启动时刻|任务结束时刻|任务总计耗时|任务平均流量|记录写入速度|读出记录总数|读写失败总数"|sed 's/\r$//g'|awk '{print $1"|"$2"|"$3"|"$4"|"}'|awk '{printf $0}'|awk -F "|" '{print "\""$3" "$4"\""",""\""$7" "$8"\""",""\""$11"\""",""\""$15"\""",""\""$19"\""",""\""$23"\""",""\""$27"\""}'`
runtime=`date "+%Y-%m-%d %H:%M:%S"`
cdataxsql="replace into cdatax_new (projectname, jobname, bizdate, jobstart, jobend, runingtime, speedsize, speedrows, allrows, errrows, runtime) values ('"${project}"','"${jobname}"','"${bizdate}"',${cdatax},'"${runtime}"');"
echo ${cdataxsql}
mysqlcmd "rcount" "${cdataxsql}"
################################################################################
exit 0