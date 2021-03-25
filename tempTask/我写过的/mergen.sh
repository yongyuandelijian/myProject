#!/bin/bash
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

#定义mysql函数
mysqlcmd()
{
sql="$1"
#rcount（v3）配置
jdbc="-h99.13.220.242 -P3306 -urcount -prcount -D rcount"
sdata=`mysql $jdbc -N -e "${sql}"`
if [[ $? -ne 0 ]];then echo "replace into rds error first, five seconds later redo";
sleep 5
sdata=`mysql $jdbc -N -e "${sql}"`;
if [[ $? -ne 0 ]];then echo "replace into rds error";exit 1;fi
fi
echo $sdata
}
#####################################################################################################
scriptPath="`pwd`"
bizDate=$1
dwmc=$2
targetTable=$3
nextDate=`date -d "${bizDate} next-day" +"%Y%m%d"`
sourceTable=$(echo ${targetTable}|sed 's/^/N_LS_/g')
projectName=$(echo ${dwmc}|sed 's/^/SC_JX_/g')
ownertablename=`echo ${targetTable}|sed 's/^N_//g'`
bbizDate=`date -d "${bizDate} 1 day ago" +"%Y%m%d"`
mydir="/home/admin/update_version"

if [ ! -d "${mydir}" ]; then mkdir "${mydir}";fi;
if [ ! -d "${mydir}/${bizDate}" ]; then mkdir "${mydir}/${bizDate}";fi;
if [ ! -d "${mydir}/${bizDate}/${dwmc}" ]; then mkdir "${mydir}/${bizDate}/${dwmc}";fi;
if [ ! -d "${mydir}/${bizDate}/${dwmc}/sql" ]; then mkdir "${mydir}/${bizDate}/${dwmc}/sql";fi;
if [ ! -d "${mydir}/${bizDate}/${dwmc}/log" ]; then mkdir "${mydir}/${bizDate}/${dwmc}/log";fi;
if [ ! -d "${mydir}/${bizDate}/${dwmc}/sqlok" ]; then mkdir "${mydir}/${bizDate}/${dwmc}/sqlok";fi;
if [ ! -d "${mydir}/${bizDate}/${dwmc}/sqlerr" ]; then mkdir "${mydir}/${bizDate}/${dwmc}/sqlerr";fi;
sql="${mydir}/${bizDate}/${dwmc}/sql"
log="${mydir}/${bizDate}/${dwmc}/log"
sqlok="${mydir}/${bizDate}/${dwmc}/sqlok"
sqlerr="${mydir}/${bizDate}/${dwmc}/sqlerr"
odpscmd="/home/admin/client/odps/bin/odpscmd --endpoint=http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api -u yXKpKuN0xKF5MLpK -p 1glCWzC8XkTT3BSpoY9NkYMibQslxB --project=sc_jc_gszj"

ossutil='/home/admin/client/ossutil'
endpoint='oss-cn-foshan-lhc-d01-a.alicloud.its.tax.cn'
accessid='yXKpKuN0xKF5MLpK'
accesskey='1glCWzC8XkTT3BSpoY9NkYMibQslxB'
${ossutil} config -e ${endpoint} -i ${accessid} -k ${accesskey}

################################
#处理基础层表结构变更
################################
#1、检查对应的表的表结构是否发生变更，检查方式：看sc_jc_gszj.oracle_table_info_compare表当天的分区中是否包含任务对应的表
lsddlsql="
select concat('alter table ','SC_JC_GSZJ','.',t1.owner,'_',t1.table_name,' add columns (',t1.column_name,' ',t1.data_type_odps,' comment ',
case when t1.column_comments is null then concat(chr(39),'null',chr(39))
else concat(chr(39),t1.column_comments,chr(39)) end,' );') as ddlsql 
FROM oracle_table_info_compare t1 where t1.rfq = '${bizDate}' and sjlybz = '${dwmc}' and concat(t1.owner,'_',t1.table_name) = '${ownertablename}';"
sqllist=`${odpscmd} -e "${lsddlsql}"|egrep -v "^\+-|ddlsql"|sed 's/|//g'|sed 's/^ //g'`
#2、根据上述检查结果，出具对应的处理方法，表结构未发生变更，则正常加载，否则，生成对应的ddl语句并执行
if [[ -n ${sqllist} ]];then
echo ${sqllist}|sed 's/; /;\n/g'|while read line;
do 
sqlname=`echo ${line}|awk '{print $3"_"$6}'|sed 's/(//g'`
echo $line
echo ${line}>${sql}/${sqlname}.sql;
tablename=`echo ${line}|sed 's/|//g'|sed 's/^ //g'|awk '{print $3}'`
echo $tablename
colname=`echo ${line}|sed 's/|//g'|sed 's/^ //g'|grep -v '^$'|awk '{print $6}'|sed 's/(//g'|tr [A-Z] [a-z]`
echo ${colname}
sql1="desc ${tablename};"
${odpscmd} -e "${sql1};"
if [[ $? -eq 0 ]];then
colvalue=`${odpscmd} -e "${sql1};"|egrep -v "Owner|TableComment|CreateTime|LastDDLTime|LastModifiedTime|InternalTable|Native Columns|Field|Partition Columns|rfq|sjlybz"|awk -F "|" '{print $2}'|grep -v "^$"|grep -w "${colname}"`
echo $colvalue
if [[ ! -n $colvalue ]];then
${odpscmd} -e "${line}" 2>${log}/${sqlname}_2.log 1>${log}/${sqlname}_1.log
status=`cat ${log}/${sqlname}_2.log|grep FAILED|egrep -v "already defined|Table not found"`
echo $status
  if [[ -n ${status} ]];then echo "version update successful" && mv ${sql}/${sqlname}.sql ${sqlok}/${sqlname}.sql; else echo "version update failed" && mv ${sql}/${sqlname}.sql ${sqlerr}/${sqlname}.sql; fi
  else 
  echo "${colname} already defined"
  fi
else 
echo "${tablename} not found " && mv ${sql}/${sqlname}.sql ${sqlok}/${sqlname}.sql;
fi
done
fi
################################
#20191129 wyz 处理基础层increment表结构变更
################################
#1、检查对应的表的表结构是否发生变更，检查方式：看sc_jc_gszj.oracle_table_info_compare表当天的分区中是否包含任务对应的表
lsddlsql1="
select concat('alter table ','SC_JC_GSZJ','.',t1.owner,'_',t1.table_name,'_increment',' add columns (',t1.column_name,' ',t1.data_type_odps,' comment ',
case when t1.column_comments is null then concat(chr(39),'null',chr(39))
else concat(chr(39),t1.column_comments,chr(39)) end,' );') as ddlsql 
FROM oracle_table_info_compare t1 where t1.rfq = '${bizDate}' and sjlybz = '${dwmc}' and concat(t1.owner,'_',t1.table_name) = '${ownertablename}';"
sqllist1=`${odpscmd} -e "${lsddlsql1}"|egrep -v "^\+-|ddlsql"|sed 's/|//g'|sed 's/^ //g'`
#2、根据上述检查结果，出具对应的处理方法，表结构未发生变更，则正常加载，否则，生成对应的ddl语句并执行
if [[ -n ${sqllist1} ]];then
echo ${sqllist1}|sed 's/; /;\n/g'|while read line1;
do 
sqlname1=`echo ${line1}|awk '{print $3"_"$6}'|sed 's/(//g'`
echo $line1
echo ${line1}>${sql}/${sqlname1}.sql;
tablename1=`echo ${line1}|sed 's/|//g'|sed 's/^ //g'|awk '{print $3}'`
echo $tablename1
colname1=`echo ${line1}|sed 's/|//g'|sed 's/^ //g'|grep -v '^$'|awk '{print $6}'|sed 's/(//g'|tr [A-Z] [a-z]`
echo ${colname1}
sql1="desc ${tablename1};"
${odpscmd} -e "${sql1};"
if [[ $? -eq 0 ]];then
colvalue1=`${odpscmd} -e "${sql1};"|egrep -v "Owner|TableComment|CreateTime|LastDDLTime|LastModifiedTime|InternalTable|Native Columns|Field|Partition Columns|rfq|sjlybz"|awk -F "|" '{print $2}'|grep -v "^$"|grep -w "${colname1}"`
echo $colvalue1
if [[ ! -n $colvalue1 ]];then
${odpscmd} -e "${line1}" 2>${log}/${sqlname1}_2.log 1>${log}/${sqlname1}_1.log
status1=`cat ${log}/${sqlname1}_2.log|grep FAILED|egrep -v "already defined|Table not found"`
echo $status1
  if [[ -n ${status1} ]];then echo "version update successful" && mv ${sql}/${sqlname1}.sql ${sqlok}/${sqlname1}.sql; else echo "version update failed" && mv ${sql}/${sqlname1}.sql ${sqlerr}/${sqlname1}.sql; fi
  else 
  echo "${colname1} already defined"
  fi
else 
echo "${tablename1} not found " && mv ${sql}/${sqlname1}.sql ${sqlok}/${sqlname1}.sql;
fi
done
fi
################################
#运行merge逻辑
################################
proLog="${scriptPath}/merge_${bizDate}_${targetTable}_`date +%Y%m%d%H%M%S`.log"
    
# set script path
if [ ! -d "${scriptPath}" ]; then 
    mkdir -p "${scriptPath}"
fi

    touch ${proLog}


# assemble SQL for OGG tables

${odpscmd} -e "desc ${projectName}.${sourceTable};" >> ${proLog}
initCols=`cat ${proLog} | grep -E 'bigint|string|boolean|double|datetime|decimal|Partition' |grep -v "before_"| awk '{print $2}' | awk '{printf $0","}'`
#add by yinqiang  check jx_tabel exists
if [[ ! -n ${initCols} ]];then echo "--${projectName}.${sourceTable} table not found!--"; exit 1; fi
echo "***********************************"
echo ${initCols}
allCols1=$(echo ${initCols%%Partition*} | tr '[a-z]' '[A-Z]') # remove Partition which is not a true field and with all partition fields right after it
echo "***********************************"
echo ${allCols1}
echo "***********************************"
allColsls=${allCols1%?}
echo ${allColsls}
allCols=$(echo ${allColsls}|sed 's/OPCODE,POSITION,READTIME,//g')
echo ${allCols}

echo "***********************************"
initCols2=`${odpscmd} -e "desc sc_jc_gszj.${targetTable};"|grep -E 'bigint|string|boolean|double|datetime|decimal|Partition' | awk '{print $2}' | awk '{printf $0","}'` #基础层表的解析结果
allCols2=$(echo ${initCols2%%Partition*} | tr '[a-z]' '[A-Z]') 
allCols2=${allCols2%?} 
echo ${allCols2}

#比较临时层和基础层的表结构，基础层多的列用null补全
targetCols=`echo ${allCols2}|sed 's/,/ /g'`
sourceCols=`echo ${allCols}|sed 's/,/ /g'`
jcallCols=$(
num=1
for tarCol in ${targetCols}
do
temp="NULL"
    for souCol in ${sourceCols}
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
       str1="${temp} as ${tarCol}"
       num=2
    else
       str1="${str1},${temp} as ${tarCol}"
    fi
done
echo ${str1})
echo "###################################"
echo ${jcallCols}
echo "***********************************"
jcallCols1=`echo ${jcallCols}|sed 's/\<SJLYBZ\>/SJLYBZ_JZ/g'`
echo ${jcallCols1}
echo "***********************************"


#获取主键，没有主键的表，默认主键为所有列
${ossutil}  cp -f oss://newlink/${dwmc}/addfilelist/${bizDate}_${dwmc}_pk.conf ${scriptPath}/${bizDate}_${dwmc}_pk.conf
if [[ $? -ne 0 ]];then echo "oss cp local error!";exit 1;fi
lsprimaryKeys=$(cat ${scriptPath}/${bizDate}_${dwmc}_pk.conf|grep -w "${targetTable}"|awk -F "|" '{print $3}'|xargs|sed 's/ /,/g')
if [[ -n ${lsprimaryKeys} ]];then primaryKeys=`echo ${lsprimaryKeys}`;
else 
initColspk=`cat ${proLog} | grep -E 'bigint|string|boolean|double|datetime|decimal|Partition' | awk '{print $2}'|grep -v "before_" |grep -vw 'opcode'|grep -vw 'position'|grep -vw 'readtime' | awk '{printf $0","}'`
allColspk=$(echo ${initColspk%%Partition*} | tr '[a-z]' '[A-Z]')
allColspk=${allColspk%?}
primaryKeys=`echo ${allColspk}|sed 's/,YPTETL_SJ//g'`; 
echo ${primaryKeys}; 
fi

before_primaryKeys=$(
for col in ${primaryKeys//,/ }
do
 before_pk=`echo ${col}|sed 's/^/BEFORE_/g'`
 echo ${before_pk} AS ${col},
done
)
before_primaryKeys=$(echo ${before_primaryKeys%,})
echo ${before_primaryKeys}

#add by yinqiang 20180615
partitioncols=$(
for col in ${primaryKeys//,/ }
do
 before_col=`echo ${col}|sed 's/^/BEFORE_/g'`
 echo "case when ${before_col} is null then ${col} else ${before_col} end,"
done
)
partitioncols=$(echo ${partitioncols%,})
echo ${partitioncols}

legacyCols=${allCols2//,/,t1.} # add 't1.' prefix for each field
echo ${legacyCols}
legacyCols1=${allCols2//,/,t0.}
echo ${legacyCols1}

# join condition string by primary key
num=1
for col in ${primaryKeys//,/ }
do
    if [ $num -eq 1 ]; then
        legacyJoinCons="on t1.${col} = t2.${col}"
        legacyFilterStr="where t2.${col} is null"
    else
        legacyJoinCons="${legacyJoinCons} and t1.${col} = t2.${col}"
    fi
    num=$[num+1]
done

######################################################
#deal with difference of columntype
######################################################


# insert string
insertStr="insert overwrite table SC_JC_GSZJ.${targetTable} partition (RFQ = '${bizDate}',SJLYBZ = '${dwmc}')"

#add by wangxing 20210301 check n_ls_table partition 
klsql="select count(*) from kelong where gmtdate='${bizDate}' and dwmc='${dwmc}';"
kelong=`mysqlcmd "${klsql}"`
#查看前一天是否有问题
if [[ ${kelong} -eq 0 ]];then
#正常加载
result=`${odpscmd} -e "select 1 from ${projectName}.${sourceTable} where rfq in ('${bizDate}','${bizDate}01','${bizDate}02') limit 1;"|grep -v "+-"|grep -v "^| _c0 "|sed 's/|//g'|sed 's/ //g'`
echo "${result}"
if [[ ! -n ${result} ]];then 
echo -e "${projectName}.${sourceTable} partition rfq=${bizDate} is not found "
finalSQL="${insertStr}
select ${jcallCols1} 
from
sc_jc_gszj.${targetTable}
where rfq = '${bbizDate}'
and sjlybz = '${dwmc}'"
echo -e "${finalSQL}"
else
#insert string to tartable
insertStr1="
insert overwrite table SC_JC_GSZJ.${targetTable} partition (RFQ = '${bizDate}',SJLYBZ = '${dwmc}') 
select ${jcallCols} 
  from (select ${allColsls},row_number() over (partition by ${partitioncols} order by cast(position as decimal) desc) as rn 
          from ${projectName}.${sourceTable} 
         where rfq >= '${bizDate}' 
           and rfq < '${nextDate}') a 
 where rn = 1 
   and opcode <> 'D'"

######判断执行Mapjoin#######
mapJoinSQL="/* + mapjoin(t2) */"
countlsSQL="count ${projectName}.${sourceTable} partition(rfq='${bizDate}');"
countlsResult=`${odpscmd} -e "${countlsSQL}"|grep  -v "^$"`
if [ $countlsResult -gt 35000000 ] ;then mapJoinSQL=""; fi





#添加子查询优化leftjoin效率 20210107
legacySelectStr0="
select t0.${legacyCols1} 
from SC_JC_GSZJ.${targetTable} t0
where t0.rfq = to_char(dateadd(to_date('${bizDate}','yyyymmdd'),-1,'dd'),'yyyymmdd')
and t0.SJLYBZ = '${dwmc}'"
#select string
legacySelectStr1="
select ${mapJoinSQL}  t1.${legacyCols} 
  from (${legacySelectStr0}) t1 
  left outer join ("

legacySelectStr2="
select ${primaryKeys}
  from ${projectName}.${sourceTable} 
 where rfq >= '${bizDate}'
   and rfq < '${nextDate}'"

legacySelectStr3="select ${before_primaryKeys}
  from ${projectName}.${sourceTable}
 where rfq >= '${bizDate}' 
 and rfq < '${nextDate}'
 and opcode in ('K','D')) t2"
legacySQL="${legacySelectStr1} ${legacySelectStr2} 
union all 
${legacySelectStr3} 
${legacyJoinCons} 
${legacyFilterStr}"
updatedSQL="select ${allCols2} 
from SC_JC_GSZJ.${targetTable} 
where rfq = '${bizDate}' 
and sjlybz = '${dwmc}'"

finalSQL="set odps.sql.mapjoin.memory.max=2048;${insertStr}
select ${jcallCols1} 
from ( ${legacySQL} 
union all
${updatedSQL}) t;"
echo "+++++++++++++基础层insertStr1 SQL+++++++++++++"
echo -e "${insertStr1};"
${odpscmd} -e "${insertStr1}"
if [ $? != 0 ]; then
echo "ERR:insert data the loss of !"
${odpscmd} -e "quit;"
exit 1;
fi
fi

else
#result不为0
result=`${odpscmd} -e "select 1 from ${projectName}.${sourceTable} where rfq in ('${bbizDate}','${bizDate}','${bizDate}01','${bizDate}02') limit 1;"|grep -v "+-"|grep -v "^| _c0 "|sed 's/|//g'|sed 's/ //g'`

echo "${result}"
if [[ ! -n ${result} ]];then 
echo -e "${projectName}.${sourceTable} partition rfq=${bizDate} is not found "
finalSQL="${insertStr}
select ${jcallCols1} 
from
sc_jc_gszj.${targetTable}
where rfq = '${bizDate}'
and sjlybz = '${dwmc}'"
echo -e "${finalSQL}"
else
#insert string to tartable
insertStr1="
insert overwrite table SC_JC_GSZJ.${targetTable} partition (RFQ = '${bizDate}',SJLYBZ = '${dwmc}') 
select ${jcallCols} 
  from (select ${allColsls},row_number() over (partition by ${partitioncols} order by cast(position as decimal) desc) as rn 
          from ${projectName}.${sourceTable} 
         where rfq >= '${bbizDate}' 
           and rfq < '${nextDate}') a 
 where rn = 1 
   and opcode <> 'D'"

######判断执行Mapjoin#######
mapJoinSQL="/* + mapjoin(t2) */"
countlsSQL="count ${projectName}.${sourceTable} partition(rfq='${bizDate}');"
countlsResult=`${odpscmd} -e "${countlsSQL}"|grep  -v "^$"`
if [ $countlsResult -gt 35000000 ] ;then mapJoinSQL=""; fi



#添加子查询优化leftjoin效率 20210107
legacySelectStr0="
select t0.${legacyCols1} 
from SC_JC_GSZJ.${targetTable} t0
where t0.rfq = to_char(dateadd(to_date('${bizDate}','yyyymmdd'),-1,'dd'),'yyyymmdd')
and t0.SJLYBZ = '${dwmc}'"
#select string
legacySelectStr1="
select ${mapJoinSQL}  t1.${legacyCols} 
  from (${legacySelectStr0}) t1 
  left outer join ("

legacySelectStr2="
select ${primaryKeys}
  from ${projectName}.${sourceTable} 
 where rfq >= '${bbizDate}'
   and rfq < '${nextDate}'"

legacySelectStr3="select ${before_primaryKeys}
  from ${projectName}.${sourceTable}
 where rfq >= '${bbizDate}' 
 and rfq < '${nextDate}'
 and opcode in ('K','D')) t2"
legacySQL="${legacySelectStr1} ${legacySelectStr2} 
union all 
${legacySelectStr3} 
${legacyJoinCons} 
${legacyFilterStr}"
updatedSQL="select ${allCols2} 
from SC_JC_GSZJ.${targetTable} 
where rfq = '${bizDate}' 
and sjlybz = '${dwmc}'"

finalSQL="set odps.sql.mapjoin.memory.max=2048;${insertStr}
select ${jcallCols1} 
from ( ${legacySQL} 
union all
${updatedSQL}) t;"
echo "+++++++++++++基础层insertStr1 SQL+++++++++++++"
echo -e "${insertStr1};"
${odpscmd} -e "${insertStr1}"
if [ $? != 0 ]; then
echo "ERR:insert data the loss of !"
${odpscmd} -e "quit;"
exit 1;
fi
fi
fi
# 20191129 wyz insert ls_ table  data to jc  table
insertStr3="OPCODE as OPCODE,POSITION as POSITION,READTIME as READTIME,"
# 20191126 jsk : alter opcode is 'D' what pk should use before
incremental_allColsls=`echo "${allColsls}"|sed 's/OPCODE,POSITION,READTIME,//g;s/,/ /g;s/YPTETL_SJ//g'`
incremental_col=""
for i in ${incremental_allColsls}
do
	i=`echo "${i}"|awk '{print "CASE WHEN "$1" IS NULL THEN BEFORE_"$1" ELSE "$1" END AS "$1","}'`
	incremental_col=`echo "${incremental_col}${i}"`
done
incremental_col=$(echo "${incremental_col}"|sed "s/^/OPCODE,POSITION,READTIME,/g;s/,$/,YPTETL_SJ/g")
insertStr2="
insert overwrite table SC_JC_GSZJ.${targetTable}_increment partition (RFQ = '${bizDate}',SJLYBZ = '${dwmc}') 
select ${insertStr3}${jcallCols} 
  from (select ${incremental_col},row_number() over (partition by ${partitioncols} order by cast(position as decimal) desc) as rn 
          from ${projectName}.${sourceTable} 
         where rfq = '${bizDate}') a 
 where rn = 1 "
echo "+++++++++++++增量识别新增三个字段+++++++++++++"
echo ${insertStr3}
echo "+++++++++++++增量数据插入Increment表SQL+++++++++++++"
echo ${insertStr2}

${odpscmd} -e "${insertStr2}"
if [ $? != 0 ]; then
echo "run insert ls_ table  data to jc  table error!!!"
exit 1;
fi
# 20191129 wyz insert ls_ table  data to jc  table


#runMerge
echo "+++++++++++++Merge -SQL+++++++++++++"
echo "${finalSQL}"
${odpscmd} -e "${finalSQL}"
if [ $? != 0 ]; then
${odpscmd} -e "quit;"
exit 1;
fi

##add $$$$  by wlt at 20200610   to deal clob task 
#################################################################################

##判断该表是否需要合并clob数据
pdsql="select count(1) from ffk_clob_column_table where dwmc = '${dwmc}' and odps_table_name = '${targetTable}';"
echo "-----------pdsql-----------"
echo ${pdsql}
pd_res=`mysqlcmd "${pdsql}"`
#获取
if [[ ${pd_res} -eq 1 ]];then
primary_key_sql="select primary_key from ffk_clob_column_table where dwmc = '${dwmc}' and odps_table_name = '${targetTable}';"
echo "-----------primary_key_sql-----------"
echo ${primary_key_sql}
primary_key_list=`mysqlcmd "${primary_key_sql}"`
echo "-----------primary_key_list-----------"
echo ${primary_key_list}

clob_column_sql="select clob_column from ffk_clob_column_table where dwmc = '${dwmc}' and odps_table_name = '${targetTable}';"
echo "-----------clob_column_sql-----------"
echo ${clob_column_sql}
clob_column_list=`mysqlcmd "${clob_column_sql}"`
echo "-----------clob_column_list-----------"
clob_column_list1=`echo ${clob_column_list} | tr [A-Z] [a-z] | sed 's/,/|/g'`
echo ${clob_column_list}

initCols3=`${odpscmd} -e "desc sc_jc_gszj.${targetTable};"|grep -E 'bigint|string|boolean|double|datetime|decimal|Partition' |grep -Evw "${clob_column_list1}" |awk '{print $2}' | awk '{printf $0","}'` 

allCols3=$(echo ${initCols3%%Partition*} | tr '[a-z]' '[A-Z]')
allCols3=${allCols3%?} 
echo ${allCols3}
legacyCols3="t1."${allCols3//,/,t1.}

num3=1
for  i in ${clob_column_list//,/ }
do 
    if [ $num3 -eq 1 ];then
	  a1="coalesce(b.$i,t1.$i) as $i,"
	else
	  a1="${a1}coalesce(b.$i,t1.$i) as $i,"
	fi
	num3=$[num3+1]
done
a1=${a1%?} 

num4=1
for  ii in ${allCols2//,/ }
do 
    if [ $num4 -eq 1 ];then
	  a2=" $ii as $ii,"
	else
	  a2="${a2} $ii as $ii,"
	fi
	num4=$[num4+1]
done
a2=${a2%?} 

insertStr2="insert overwrite table SC_JC_GSZJ.${targetTable} partition (RFQ = '${bizDate}',SJLYBZ = '${dwmc}') select ${mapJoinSQL}"

whereStr="
  from SC_JC_GSZJ.${targetTable} t1 
  left outer join ( select ${primary_key_list},${clob_column_list} from SC_JX_${dwmc}.${targetTable}_CLOB  where rfq='${bizDate}') b
on t1.${primary_key_list}=b.${primary_key_list}
where t1.rfq='${bizDate}' and t1.sjlybz='${dwmc}'"

finalSQL2="set odps.sql.mapjoin.memory.max=2048;${insertStr2}
${a2} from 
( select 
${legacyCols3},${a1} 
${whereStr}
)t;
"

echo -e "${finalSQL2}"
${odpscmd} -e "${finalSQL2}"
if [ $? != 0 ]; then
${odpscmd} -e "quit;"
exit 1;
fi

fi  ## 对应判断表是否需要合并表的

##### add $$$$

#####################
#新增数据统计逻辑
#####################
#获取merge逻辑的output结果
count2=`cat *.log|grep -A1 outputs|grep -i sc_jc_gszj|grep -iw "${targetTable}"|awk 'END {print}'|sed 's/ //g'|awk -F ':' '{print $2}'|awk -F '(' '{print $1}'`
#历史数据
runtime2=`date "+%Y-%m-%d %H:%M:%S"`
resql="replace into new_ctable_odps (projectname, jobname, bizdate, count1, runtime1, count2, runtime2) values ('"${projectName}"','"${targetTable}"','"${bizDate}"','','','"${count2}"','"${runtime2}"');"
#结果写入rds的表new_ctable_odps
echo ${resql}
mysqlcmd "${resql}"
