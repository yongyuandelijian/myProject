#!/bin/bash
# 代码去重的union_data,需要修改原代码目标分区为 【分区0】
# 修改时间20201014

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
    wget -P ${tdir} http://sjjc.oss-cn-foshan-lhc-d01-a.ops.its.tax.cn/Tools/client.tar.gz && cd ${tdir} && tar -zxvf client.tar.gz -C ${tdir}
    if [[ $? -ne 0 ]];then echo "tar failed";rm -rf ${tdir}/client;else mkdir "${tdir}/chkend";fi
 fi
fi
#####################################################################################################
#定义mysql函数
mysqlcmd()
{

sdata=`mysql $jdbc -N -e "${sql}"`
if [[ $? -ne 0 ]];then echo "select rds error";exit 1;fi
echo $sdata
}
init()
{
    odpscmd="/home/admin/client/odps/bin/odpscmd "
    scriptPath="`pwd`"
    targetProjectproLog="${scriptPath}/union_${bizDate}_${targetTable}_`date +%Y%m%d%H%M%S`.log"
    sourceProjectproLog="${scriptPath}/union_${bizDate}_${sourceTable}_`date +%Y%m%d%H%M%S`.log"

    # set script path
    if [ ! -d "${scriptPath}" ]; then 
        mkdir -p "${scriptPath}"
    fi
    touch ${targetProjectproLog}
    touch ${sourceProjectproLog}
}

# assemble
assemble()
{
    #目标表非分区字段
    ${odpscmd} -e "desc ${targetProject}.${targetTable};" > ${targetProjectproLog}
    initTarCols=`grep -E 'bigint|string|boolean|double|datetime|decimal' ${targetProjectproLog} | grep -vw 'rfq' | grep -vw 'sjlybz' | awk '{print $2}' | awk '{printf $0" "}' | tr '[a-z]' '[A-Z]'`
    #源表去掉Partition
    ${odpscmd} -e "desc ${sourceProject}.${sourceTable};" > ${sourceProjectproLog}
    initSouCols=`grep -E 'bigint|string|boolean|double|datetime|decimal' ${sourceProjectproLog} | awk '{print $2}' | awk '{printf $0" "}' | tr '[a-z]' '[A-Z]'`
   

	sjly=${sourceProject:6:4}


    #比较源表和目标表非分区字段是否一致，如果目标表非分区字段比源表分区字段多，则写成null AS
     num=1
     for tarCol in ${initTarCols}
     do
     temp="NULL"
         for souCol in ${initSouCols}
         do
            if [ "$tarCol" == "$souCol" ]
            then
                temp=$souCol
                break
            fi 
            if [[ "$tarCol" == "SJLYBZ_JZ" && "$souCol" == "SJLYBZ" ]]
            then
            temp="SJLYBZ"
            fi
         done
         if [ $num -eq 1 ]
         then
            str1="${temp} AS ${tarCol}"
            num=2
         else
            str1="${str1} , 
         ${temp} AS ${tarCol}"
         fi
     done
    
     # assemble SQL  修改目标分区到原数据分区
    insertStr="INSERT OVERWRITE TABLE ${targetProject}.${targetTable} partition (rfq = '${bizdate_ysj}',sjlybz = '${sjly}')"    
    selectStr="
    SELECT 
    ${str1} 
    FROM 
    ${sourceProject}.${sourceTable} 
    WHERE rfq = '${bizDate}'"
    
    finalSQL_temp="${insertStr} 
    ${selectStr};"

    finalSQL=$(echo "${finalSQL_temp}"|sed -e 's/ DATE / `DATE` /g')
    echo "${finalSQL}"
}

runUnion()
{
    ${odpscmd} -e "${finalSQL}"
    if [ $? != 0 ]; then
        ${odpscmd} -e "quit;"
        exit 1;
    fi
}

#--------------- program start -------------------
scriptName=$0
bizDate=$1 #业务日期
sourceTable=$2 #odps镜像层表名
targetTable=$3 #odps基础层表名
sourceProject=$(echo $4 | tr '[a-z]' '[A-Z]') #odps镜像层项目名称
targetProject=$5 #odps基础层项目名称
bizdate_ysj="${bizDate}0"

if [ $# != 5 ]; then
    echo "not enough arguments: expect 5 but get $#!"
    exit 1;
fi

#################################################################################mj 20170526 update
#update on 20180816
export ORACLE_HOME=/home/admin/client/oracle
export LD_LIBRARY_PATH=/home/admin/client/oracle/lib
export PATH=$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH
dwmc=`echo $sourceProject|awk -F "_" '{print $3}'| tr '[a-z]' '[A-Z]'`
sourceTable1=`echo ${sourceTable}| tr '[a-z]' '[A-Z]'`
#根据表名称来确定GSZJ目录下DataSource的数据源
if   [[ ${dwmc} == "GSZJ" ]] && [[ `echo "$sourceTable1"|grep "J1_CKTS_"` ]];then
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'J1_CKTS';"
#add by wlt
elif   [[ ${dwmc} == "GSZJ" ]] && [[ `echo "$sourceTable1"|grep "J1_JSSJ_"` ]];then
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'J1_FWSK';"
elif   [[ ${dwmc} == "GSZJ" ]] && [[ `echo "$sourceTable1"|grep "J1_FWSK_"` ]];then
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'J1_FWSK';"
elif   [[ ${dwmc} == "GSZJ" ]] && [[ `echo "$sourceTable1"|grep "FATCAI_"` ]];then
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'FATCAI';"
elif [[ ${dwmc} == "GSZJ" ]] && [[ `echo "$sourceTable1"|grep "^HX_"` ]];then
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'HX';"
elif [[ ${dwmc} == "GSZJ" ]] && [[ `echo "$sourceTable1"|grep "WBJH_"` ]];then
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'WBJH';"
elif [[ ${dwmc} == "DLST" ]];then
    if [[ `echo "$jobname"|grep "^WS"` ]];then
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'WS';"
    else
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'HX_ZG';"
    fi
elif [[ ${dwmc} == "GDST" ]] ;then
    if [[ `echo "$jobname"|grep "^GDET"` ]];then
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'GDET';"
    else
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'HX_ZG';"
    fi
else
sqldb="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}';"
fi
echo ${sqldb}
mysqlcmd "rcount" "${sqldb}"
db=`echo ${sdata}  |awk -F "|" '{print $1}'`
jdbc=`echo ${sdata}|awk -F "|" '{print $2}'`
user=`echo ${sdata}|awk -F "|" '{print $3}'`
pass=`echo ${sdata}|awk -F "|" '{print $4}'`

#list=`cat /home/admin/version/${dwmc}/column.conf |grep "|${sourceTable1}|"`
sql="select case when swhere = '' then concat(project, '|', odps_tablename, '|', oracle_owner, '|', oracle_tablename, '||', columns)
                else concat(project, '|', odps_tablename, '|', oracle_owner, '|', oracle_tablename, '||', columns, '|', swhere) end
         from column_conf
         where dwmc = '${dwmc}' and odps_tablename = '${sourceTable1}' ;"
echo ${sql}
list=`mysqlcmd "rcount" "${sql}"`
echo ${list}

stable=`echo $list|awk -F '|' '{print $3"."$4}'`
echo ${stable}

VALUE=`sqlplus -S ${user}/${pass}@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
select 1 from dual where exists (select 1 from $stable where $owhere 1=1);
quit;
END`
if [[ $? -ne 0 ]];then echo "select oracle error";exit 1;fi
echo ${VALUE}
if [[ ! $VALUE ]];then echo -e " 0行记录，程序结束\nX----------------X";exit 0;fi

#################################################################################mj 20170526 update
# 初始化
init

assemble

# 写LOG
echo "${finalSQL}" >> ${targetProjectproLog}
echo "bizDate=$1" && echo "bizDate=$1" >> ${targetProjectproLog}
echo "sourceTable=$2" && echo "sourceTable=$2" >> ${targetProjectproLog}
echo "targetTable=$3" && echo "targetTable=$3" >> ${targetProjectproLog}
echo "sourceProject=$4" && echo "sourceProject=$4" >> ${targetProjectproLog}
echo "targetProject=$5" && echo "targetProject=$5" >> ${targetProjectproLog}

# 执行SQL语句
runUnion

exit 0