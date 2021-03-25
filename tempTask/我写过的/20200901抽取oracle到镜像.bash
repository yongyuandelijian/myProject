#!/bin/bash
#业务日期
bizdate=$1
#单位名称
dwmc=$2
mydir=`pwd`
project=$3
################################################################################
#oracle sqlplus环境变量
################################################################################
export ORACLE_HOME=/opt/oracle
export LD_LIBRARY_PATH=/opt/oracle/lib
export PATH=$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH
################################################################################
#######################################################################
#rcount（v3）配置                                                     #
#######################################################################
rdbanme=3333                                                        #
rhostname=127.0.0.1                                               #
rusername=1111                                                      #
rpassword=2222                                                      #
rport=4444                                                            #
####################################################################### 
################################################################################ 
#ODPS 配置          --下面部分都是 ODPS 配置的内容                             #
################################################################################ 
odpsServer="1111"     #
tunnelServer="2222"            #
odpsaccessId="3333"                                                #
odpsaccessKey="4444"                                 #
################################################################################

#临时文件夹
testdir="${mydir}/${dwmc}"
if [ ! -d "${mydir}/${dwmc}" ]; then mkdir "${mydir}/${dwmc}";fi;

if [[ ${bizdate} ]];then
  rm -rf ${testdir}/${bizdate}
  myjson="${testdir}/${bizdate}/json"
  mylog="${testdir}/${bizdate}/log"
  if [ ! -d "${testdir}/${bizdate}" ]; then mkdir "${testdir}/${bizdate}";fi;
  if [ ! -d "${testdir}/${bizdate}/json" ]; then mkdir "${testdir}/${bizdate}/json";fi;
  if [ ! -d "${testdir}/${bizdate}/log" ]; then mkdir "${testdir}/${bizdate}/log";fi;
else
  myjson="${testdir}/json"
  mylog="${testdir}/log"
  rm -rf ${testdir}/json
  rm -rf ${testdir}/log
  if [ ! -d "${testdir}/json" ]; then mkdir "${testdir}/json";fi;
  if [ ! -d "${testdir}/log" ]; then mkdir "${testdir}/log";fi;
fi

################################################################################ 
#获取配置信息 
################################################################################ 
#dbsql="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}';"
#echo ${dbsql}
#datasource=`mysql -h${rhostname} -P${rport} -u${rusername} -p${rpassword} -D ${rdbanme} -N -e "${dbsql}"`
#if [[ $? -ne 0 ]];then echo "select rds error";exit 1;fi
#db=`echo ${datasource}  |awk -F "|" '{print $1}'`
#jdbc=`echo ${datasource}|awk -F "|" '{print $2}'`
#user=`echo ${datasource}|awk -F "|" '{print $3}'`
#pass=`echo ${datasource}|awk -F "|" '{print $4}'`
source /home/admin/version/${dwmc}/datasource.conf
#######################
#生成新的column配置文件
#######################
if [ -f ${mydir}/${dwmc}/column.conf ];then rm -f "${mydir}/${dwmc}/column.conf";fi
for i in `cat ${mydir}/${dwmc}.list|sed 's/\./_/g'`
do
column1=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set linesize 30000
set verify off
set echo off
select t1.owner || '_' || t1.TABLE_NAME || '|' || t1.owner || '|' ||
       t1.TABLE_NAME || '||'
  from sys.dba_tab_cols t1
 where t1.owner || '_' || t1.TABLE_NAME = upper('${i}')
 group by t1.owner || '_' || t1.TABLE_NAME || '|' || t1.owner || '|' ||
          t1.TABLE_NAME || '||';
quit;
END`
column2=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set linesize 30000
set verify off
set echo off
select t1.column_name from sys.dba_tab_cols t1 where t1.owner||'_'||t1.TABLE_NAME  = upper('${i}') and t1.DATA_TYPE  not in ('LONG','NCLOB', 'CLOB','BLOB','BFILE','CFILE') and t1.COLUMN_NAME not like '%$%' and t1.VIRTUAL_COLUMN <> 'YES';
quit;
END`
column2=`echo ${column2}|sed 's/ /,/g'`
echo ${project}"|"${column1}${column2}>>${mydir}/${dwmc}/column.conf
done
################################################

for jobname in `cat ${mydir}/${dwmc}.list`
do
list=`cat ${mydir}/${dwmc}/column.conf |grep "|${jobname}|"` 
if   [[ ! $list ]];then "配置文件中没有这个表";echo ${jobname} >>${mydir}/${dwmc}/tablenotfound.txt ;fi

################################################################################
#获取表用户和表名称
################################################################################
owner=`echo $list|awk -F '|' '{print $3}'`
table_name=`echo $list|awk -F '|' '{print $4}'`

################################################################################
#获取分区表的信息 modify by wlt at 2019.2.2
################################################################################
PT=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
select partition_name
  from sys.dba_tab_partitions
 where table_name =upper('${table_name}')
   and table_owner=upper('${owner}')
;
quit;
END`
if [[ $? -ne 0 ]];then echo "pt error";echo "${table_name}">>${mydir}/${dwmc}/pr_error.txt;fi
#PT=`echo -e "$PT"|awk '{printf $0}'`
echo ${PT} 
if [[ ${PT} ]];then echo "${jobname}" >>${dwmc}_${bizdate}_pt_result.txt;fi
################################################################################
#ORACLE 配置
################################################################################ 
swhere=""
sselect=`echo $list|awk -F '|' '{print $6}'|tr '[A-Z]' '[a-z]'`
echo $sselect
sselect=`echo -n $sselect|awk '{gsub(/,/,"\",\"",$0);print "\""$0"\""}'`
##把表的列变成json需要的格式
oselect="${sselect}"
jobname1=`echo ${jobname}`
DT=`/home/admin/odps/bin/odpscmd --project=${project} -e "desc ${project}.${jobname1}";`
DT=`echo "$DT"|sed 's/ //g'|grep "|datetime|"|awk -F "|" '{print $2}'`
echo "--$DT--"
if [[ $DT ]];then 
for i in `echo $DT|tr '[A-Z]' '[a-z]'` ;do echo
oselect=`echo ${oselect}|sed 's/"'"${i}"'"/"case when '${i}' <to_date(00010101,yyyymmdd) then to_date(00010101,yyyymmdd) when '${i}' >to_date(99991231235959,yyyymmddhh24miss) then null else '${i}' end"/g'` 
done
oselect=`echo -e "${oselect}"|sed 's/"/\\"/g'`
fi

##处理类型为char的字段
#获取字段
cselect="${oselect}"
charcol=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
select t.column_name from sys.dba_tab_columns t 
where t.owner = upper('${owner}')
and t.table_name=upper('${table_name}')
and t.data_type = 'CHAR';
quit;
END`

if [[ ${charcol} ]];then
for i in `echo $charcol|tr '[A-Z]' '[a-z]'`;do echo 
cselect=`echo $cselect|sed 's/"'"${i}"'"/"'"trim(${i})"'"/g'`
done
fi

################################################################################ 
#ODPS 配置
################################################################################ 
project=`echo $list|awk -F '|' '{print $1}'`
table=`echo $list|awk -F '|' '{print $2}'`
select=`echo $list|awk -F '|' '{print $6}'|tr '[a-z]' '[A-Z]'`
select=`echo -n $select|awk '{gsub(/,/,"\",\"",$0);print "\""$0"\""}'`
partition=${bizdate}
truncate="true"

################################################################################
#JSON 配置
################################################################################ 
passa=`echo ${pass}|grep "\""|sed 's/"/\\\"/g'`
if [[ $passa ]];then pass="$passa";fi 
if [[ $PT ]];then 
speed="10"                                          ##设置并发进程
#########################adsspk#modify by wlt ################################
#sspk=`/home/admin/odps/bin/odpscmd --project="${project}" -e "desc ${table};" |grep primary |awk -F '|' '{print $2}' |sed s/[[:space:]]//g | sed -n '1p' |tr '[a-z]' '[A-Z]'`
#msg="==================The primary key is : ==>${sspk}<============================"
#echo -e "\033[43;35m $msg \033[0m \n";
sspk=""
################################################################################
for i in ${PT}
do
ttable=`echo $list|awk -F '|' '{print $3"."$4}'`
sstable="${ttable}_${i}"
partition="${i}"
json="{
\"job\": {
  \"content\":[
    {
      \"reader\":{
        \"name\":\"${db}\",
        \"parameter\":{
          \"column\":[${cselect},
            \"sysdate\"
          ],
          \"connection\":[
            {
              \"jdbcUrl\":[
                \"jdbc:oracle:thin:@${jdbc}\"
              ],
              \"table\":[
                \"${ttable} PARTITION (${i})\"
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
           \"partition\":\"rfq=${partition}\",
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
#列的字符均被定义为大写，所有的关键字在这里做转换
echo $json|sed -e 's/"date"/"\\"date\\""/g;s/"timestamp"/"\\"timestamp\\""/g'>${myjson}/${project}${sstable}.json
sed -i "s/00010101,yyyymmdd/'00010101','yyyymmdd'/g" ${myjson}/${project}${sstable}.json
sed -i "s/99991231235959,yyyymmddhh24miss/'99991231235959','yyyymmddhh24miss'/g" ${myjson}/${project}${sstable}.json
#nohup python /home/admin/datax/bin/datax.py ${myjson}/${project}${sstable}.json>${mylog}/${project}${sstable}.log 2>&1 & 
done
else
speed="10"
stable=`echo $list|awk -F '|' '{print $3"."$4}'`
sstable=`echo $list|awk -F '|' '{print $3"."$4}'`
#sspk=`/home/admin/odps/bin/odpscmd --project="${project}" -e "desc ${table};" |grep primary |awk -F '|' '{print $2}' |sed s/[[:space:]]//g | sed -n '1p' |tr '[a-z]' '[A-Z]'`
#msg="==================The primary key is : ==>${sspk}<============================"
#echo -e "\033[43;35m $msg \033[0m \n";
sspk=""
core="
\"core\":{
  \"transport\":{
    \"channel\":{
      \"speed\":{
        \"byte\":\"-1\",
        \"record\":\"-1\"
     }  }
  }
},
"
json="{
${core}
\"job\": {
  \"content\":[
    {
      \"reader\":{
        \"name\":\"${db}\",
        \"parameter\":{
          \"column\":[${cselect},
            \"sysdate\"
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
           \"partition\":\"rfq=${partition}\",
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
#列的字符均被定义为大写，所有的关键字在这里做转换
echo $json|sed -e 's/"date"/"\\"date\\""/g;s/"timestamp"/"\\"timestamp\\""/g'>${myjson}/${project}${sstable}.json
sed -i "s/00010101,yyyymmdd/'00010101','yyyymmdd'/g" ${myjson}/${project}${sstable}.json
sed -i "s/99991231235959,yyyymmddhh24miss/'99991231235959','yyyymmddhh24miss'/g" ${myjson}/${project}${sstable}.json
#nohup python /home/admin/datax/bin/datax.py --jvm="-Xms1g -Xmx4g" ${myjson}/${project}${sstable}.json>${mylog}/${project}${sstable}.log 2>&1 & 
fi
done
echo "---------------json made over-----------------------------------------------"