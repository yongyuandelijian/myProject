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
#####################################################################################################
dwmc=$1
bizdate=$2
db=rcount
user=rcount
pass=rcount
host=99.13.220.242
port=3306
umask=022
##
dwm=${dwmc}
curDate=${bizdate}
mydir=/home/admin/runsql_log
odpscmd="/home/admin/client/odps/bin/odpscmd --endpoint=http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api -u yXKpKuN0xKF5MLpK -p 1glCWzC8XkTT3BSpoY9NkYMibQslxB"
if [ "$dwmc" == "GSZJ" ];then project="SC_JX_GSZJ"
elif [ "$dwmc" == "JC_GSZJ" ];then project="SC_JC_GSZJ"
elif [ "$dwmc" != "GSZJ" ] && [ "$dwmc" != "JC_GSZJ" ];then project="SC_JX_${dwmc}";
fi
##
if [ ! -d "${mydir}" ]; then mkdir "${mydir}";fi;
if [ ! -d "${mydir}/${dwmc}" ]; then mkdir "${mydir}/${dwmc}";fi;
if [ ! -d "${mydir}/${dwmc}/${bizdate}" ]; then mkdir "${mydir}/${dwmc}/${bizdate}";fi;
testdir="${mydir}/${dwmc}/${bizdate}"
if [ ! -d "${testdir}/log" ]; then mkdir "${testdir}/log";fi;
if [ ! -d "${testdir}/sql" ]; then mkdir "${testdir}/sql";fi;
if [ ! -d "${testdir}/sqlok" ]; then mkdir "${testdir}/sqlok";fi;
if [ ! -d "${testdir}/sqlerr" ]; then mkdir "${testdir}/sqlerr";fi;
mylog="${testdir}/log"
mysql="${testdir}/sql"
mysqlok="${testdir}/sqlok"
mysqlerr="${testdir}/sqlerr"
if [ "`ls -A ${mysqlerr}`" != "" ];then echo "${mysqlerr} is not empty"; cd ${mysqlerr};rm -f *.sql;else echo "${mysqlerr} is empty";fi 
#执行更新镜像层和基础层ODPS表结构的语句	 
update_odps_sql=`mysql -h${host} -P${port} -u${user} -p${pass} -D${db} <<END
     SET SESSION group_concat_max_len = 102400;
     set names utf8;
     SELECT concat(a.uid,'|',a.odps_sql) FROM odps_ddl_sql a where a.pro_name='${project}';
END`
if [[ $? -eq 0 ]];then
echo ${update_odps_sql} > ${testdir}/${curDate}.${dwm}.execute_odps.sql
else
echo "get documents err,please check";exit 1;
fi
##made sql
cat ${testdir}/${curDate}.${dwm}.execute_odps.sql | sed 's/;/;\n/g'| sed "s/concat(a.uid,'|',a.odps_sql)//" | while read line
do
name=`echo ${line} | awk -F '|' '{print $1}'`
num=`echo $line | awk -F '|' '{print NF-1}'`
if [[ ${num} -eq 1 ]];then
echo $line | awk -F '|' '{print $2}' > ${mysql}/${name}.sql
else [[ ${num} -gt 1 ]]
echo $line | awk -F '|' '{print $2 "||" $4}' > ${mysql}/${name}.sql
fi
done
echo ${project}
#定义脚本开始运行时间
start_time=`date +%s`
[ -e /tmp/fd1 ] || mkfifo /tmp/fd1      #创建有名管道
exec 3<>/tmp/fd1                        #创建文件描述符，以可读(<)可写(>)的方式关联管道文件，这时候文件描述符3就有了有名管道文件的所有特性
rm -rf /tmp/fd1                         #关联后的文件描述符拥有管道文件的所有特性，所以这时候管道文件可以删除，我们留下文件描述符来用即可
for ((i=1;i<=30;i++))                   #此处可以控制并发
do 
    echo >&3                            #&3代表引用文件描述符3，这条命令代表往管道里面放入了一个"令牌"
done
#执行ddlsql
for i in `ls ${mysql}`
do
read -u3
echo ${i}
cat ${mysql}/$i
{
    ${odpscmd} --project=${project} -f ${mysql}/$i 2>${mylog}/${i}.2 1>${mylog}/${i}.1
    value=`cat ${mylog}/${i}.2|grep FAILED|grep -v "already defined"`
    if [ "$value" == "" ];then
       mv ${mysql}/$i ${mysqlok}/$i
    else 
       mv ${mysql}/$i ${mysqlerr}/$i
    fi
    echo >&3                            #代表这一次命令执行到最后，把令牌放回管道
}&
done
wait
countsql=`ls ${mysqlerr} |wc -l`
echo ${countsql}
if [ "$countsql" == "0" ];then
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>DDLSQL run over <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  stop_time=`date +%s`
  echo ${start_time}
  echo ${stop_time}
  echo "TIME:`expr $stop_time - $start_time`"
  exec 3<&-                               #关闭文件描述符的读
  exec 3>&-                               #关闭文件描述符的写
  exit 0
else 
  echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>DDLSQL run failed <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
  exec 3<&-                               #关闭文件描述符的读
  exec 3>&-                               #关闭文件描述符的写
  exit 1
fi
#################################################################################################
exit 0
