#!/bin/bash
# 按照给定的表单从oracle 源段获取主键
# 参数 1 表单文件名称(table.list存储odps表名称)  2 oracle owner（虽然拼接可以进行比对，但是为了防止不对，所以提供比较好）
# 注意：一次只能操作一个owner下的表
# 李鹏超 20201021
# 输入变量
scriptname=$1
owner=$2

# 如果参数个不符合规则停止执行，防止带入造成较大问题
if [ $# -ne 2 ] || [ -z ${owner} ] || [ ! -f ${scriptname} ];then 
echo "\033[0;31;5m参数异常\033[0m; 要求的参数个数是scriptname和owner共2个，且owner不能为空,${scriptname}普通文件必须存在,当前提供的参数是$#个，分别是$* 请检查核对参数！！！"; exit -1; 
fi;

# 执行sqlplus需要的变量
export ORACLE_HOME=/opt/oracle
export LD_LIBRARY_PATH=/opt/oracle/lib
export PATH=$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH


#定义rcount函数
rcountcmd()
{
sql="$1"
#rcount（v3）配置
jdbc="-h99.13.220.242 -P3306 -urcount -prcount -D rcount"
rcount_result=`mysql $jdbc -N -e "${sql}"`
if [[ $? -ne 0 ]];then echo "rcount excute failed";exit -1;fi
# echo "查询结果：${rcount_result}"
}

# 处理目录
if [ -f getpkerr.log ]; then rm -f getpkerr.log; fi;
if [ -f updatepk.ok ]; then rm -f updatepk.ok; fi;
if [ -f updatepk.err ]; then rm -f updatepk.err; fi;
# 获取源段连接方式
get_consql="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = 'GSZJ' and sysname='DB_ZG';"
echo "${get_consql}"
rcountcmd "${get_consql}"
db=`echo ${rcount_result}  |awk -F "|" '{print $1}'`
jdbc=`echo ${rcount_result}|awk -F "|" '{print $2}'`
user=`echo ${rcount_result}|awk -F "|" '{print $3}'`
pass=`echo ${rcount_result}|awk -F "|" '{print $4}'`

odpscmd='/home/admin/client/odps/bin/odpscmd --endpoint=http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api -u yXKpKuN0xKF5MLpK -p 1glCWzC8XkTT3BSpoY9NkYMibQslxB --project=SC_JX_GSZJ'

# 准备并发
if [ -e tempfifo ]; then rm -f tempfifo; fi;
mkfifo ./tempfifo;
# 将管道文件的属性传递给文件描述符
exec 3<> ./tempfifo
rm -f tempfifo
# 创建令牌
for i in `seq 1 20`
do
echo >&3
done;


# 循环表单获取主键并更新到rcount中
for tablename in `cat table.list |tr [a-z] [A-Z]`
do
oracle_tablename=`echo "${tablename}"|sed s/^${owner}_//g`
read -u3
{
# 查询oracle主键，
getpk_sql="select COLUMN_NAME from all_cons_columns where table_name='${oracle_tablename}' and constraint_name in (select constraint_name from all_constraints where owner='${owner}' and table_name='${oracle_tablename}' and constraint_type='P');"
echo "查询主键sql是${getpk_sql}"
pk=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set linesize 30000
set verify off
set echo off
${getpk_sql}
quit;
END`

if [ $? -ne 0 ]; then echo "执行${getpk_sql}发生 \033[0;31;5m错误\033[0m;"; >> getpkerr.log; continue; fi;
echo "oracle 查询到的 ${pk}"
# 如果主键为空，由于uuid在数据量多的时候无法切开，所以取第一个列
if [ ! -z "${pk}" ];  then
pk=`echo "${pk}"|awk '{printf $1","}' |awk -F ',' '{print $1}'`   # 如果主键为1个或者多个，则获取第一个
else
pk=`${odpscmd} -e "desc ${tablename};"|grep -E 'string|double|datetime' |awk -F '|' '{printf $2}'|awk '{print $1}'`; 
fi;

update_sql="update column_conf set splitpk='${pk}' where oracle_owner='DB_ZG' and odps_tablename='${tablename}';"
echo "更新sql是：${update_sql}"
rcountcmd "${update_sql}"
if [ $? -eq 0 ]; then 
echo "执行 ${tablename} 更新成功;" >> updatepk.ok; 
else
echo "执行 ${tablename} 更新失败;" >> updatepk.err;
continue; fi;

echo >&3     # 交回令牌
} &
done;

wait;

exec 3>&-	# 关闭写 不能有空格
exec 3<&-	# 关闭读

exit 0