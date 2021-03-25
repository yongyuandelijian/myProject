#!/bin/bash
# 功能：生成创建ads表的脚本   使用到的文件 tablist 里面需要用到的格式 (SC_ZJ_GSZJ_2|ZJ_SWJG_DJ_XBDJHS_BY_HZ|本期新办登记户数汇总|qxjswjg_dm)
# 参数：dwmc (GSZJ_2 创建文件夹使用)
# 用法：sh makesql.sh GSZJ_2
# 时间：aaa 202000928
mydir=`pwd`
dwmc=$1
#create new documents
testdir="${mydir}/${dwmc}"
mylog="${testdir}/log"
mysql="${testdir}/sql"
if [ ! -d "${mysql}" ]; then mkdir -p "${mysql}";fi;
if [ ! -d "${mylog}" ]; then mkdir -p "${mylog}";fi;

odpscmd="/home/admin/client/odps/bin/odpscmd --endpoint=http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api -u yXKpKuN0xKF5MLpK -p 1glCWzC8XkTT3BSpoY9NkYMibQslxB"
echo '' >${testdir}/table_not_fount.list
for i in `cat ${mydir}/tablist`
do
i=`echo ${i}|sed 's/ //g'` # 先将空格去除防止对结果造成影响
project=`echo ${i}|awk -F "|" '{print $1}'|tr '[A-Z]' '[a-z]'`
sourceTable=`echo ${i}|awk -F "|" '{print $2}'|tr '[A-Z]' '[a-z]'`
pk=`echo ${i}|awk -F "|" '{print $4}'|tr '[A-Z]' '[a-z]'`
echo "要处理的表是：${project}>>>${sourceTable}分割主键是：${pk}"  
if [ -z ${pk} ];then echo "${sourceTable} have not found PK";exit 1;fi
#check table exists
# echo "${odpscmd} --project=${project} -e \"desc ${sourceTable};\"|grep 'Table not found'|wc -l"
result=`${odpscmd} --project=${project} -e "desc ${sourceTable};"|grep 'Table not found'|wc -l`
if [ ${result} -gt 0 ];then
echo "${sourceTable} not found in ${project}" ;
echo $i >> ${testdir}/table_not_fount.list
else
#export table
echo "----------拼接语句开始----------------"
# sql1=`${odpscmd} --project=SC_ZJ_GSZJ_2 -e "export table ZJ_ZZ_SSXW_SBTZ_ZZS_DJXH_BQ;"|grep '^DDL:'|sed 's/^DDL://g'|sed 's/\<string\>/varchar/g'|sed 's/\<datetime\>/timestamp/g'|awk -F "partitioned " '{print $1}'`
sql1=`${odpscmd} --project=${project} -e "export table ${sourceTable};"|grep '^DDL:'|sed 's/^DDL://g'|sed 's/\<string\>/varchar/g'|sed 's/\<datetime\>/timestamp/g'|awk -F "partitioned " '{print $1}'` 
# echo ${sql1}
sql2=`echo ${sql1}|awk -F ") comment" '{print $1}'|sed 's/$/) /g'|sed "s/$/PARTITION BY HASH KEY (${pk}) PARTITION NUM 256  TABLEGROUP sdhy  OPTIONS (UPDATETYPE='batch')/g"`
# echo $sql2
sql3=`echo ${sql1}|awk -F ") comment" '{print $2}'|sed 's#^# comment #g'|sed 's#$#;#g'`
echo "$sql2' '$sql3"

fsql=`echo "$sql2' '$sql3"`
echo ${fsql} >${mysql}/${project}${sourceTable}.sql
fi
done