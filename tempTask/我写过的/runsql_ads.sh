#!/bin/bash
# ----------------------------------------------------------------------------------
# 功能：执行创建ads表的脚本
# 参数：dwmc (GSZJ_2) num 并发 (10)
# 用法：sh runsql.sh GSZJ_2 5
# 时间：aaa 202000928
# ----------------------------------------------------------------------------------
#地区
dwmc=$1
#作业并发度
num=$2
#临时文件夹
mydir=`pwd`
testdir="${mydir}/${dwmc}"
mylog="${testdir}/log"
mysql="${testdir}/sql"
mysqlok="${testdir}/sqlok"
mysqlerr="${testdir}/sqlerr"
if [ ! -d "${mylog}" ]; then mkdir -p "${mylog}";fi;
if [ ! -d "${mysql}" ]; then mkdir -p "${mysql}";fi;
if [ ! -d "${mysqlok}" ]; then mkdir -p "${mysqlok}";fi;
if [ ! -d "${mysqlerr}" ]; then mkdir -p "${mysqlerr}";fi;

mysqlcmd='mysql -hquickbi-ysc-c7e3a660.cn-foshan-lhc-am338001-a.alicloud.its.tax.cn -P10691 -uTiGFmfEFPp7zvGvs -pgXimYLRulwZa8rBUOWlpybD200WVRL -D quickbi_ysc'
#等待后台挂起作业完成
waiting()
{
  while true
  do
    Begin=`cat ${mylog}/$1|grep "$1_Begin"|wc -l`
    End=`cat ${mylog}/$1|grep "$1_End"|wc -l`
    jobs=$[$Begin-$End]
    if [[   $2 ]] && [[ $jobs -lt $2 ]];then break;fi
    if [[ ! $2 ]] && [[ $jobs -eq 0  ]];then break;fi
    sleep 0.3;
  done
}
#日志
loging()
{
  if   [[ $1 -eq 1 ]];then
    echo "$3 $2_Begin `date +'%Y-%m-%d %H:%M:%S'`">>${mylog}/$2
  elif [[ $1 -eq 2 ]];then
    echo "$3 $2_End `date +'%Y-%m-%d %H:%M:%S'`">>${mylog}/$2
  elif [[ $1 -eq 3 ]];then
    echo "$3 $2_End ERR `date +'%Y-%m-%d %H:%M:%S'`">>${mylog}/$2
  fi
}

>${mylog}/${dwmc}
for i in `ls ${mysql}`
do
  echo ${i}
  cat ${mysql}/$i
  loging "1" "${dwmc}" "$i";
  sleep 0.2;
  nohup $mysqlcmd < ${mysql}/$i 2>${mylog}/${i}.2 1>${mylog}/${i}.1 && ( loging "2" "${dwmc}" "$i" && mv ${mysql}/$i ${mysqlok}/$i ) || ( loging "3" "${dwmc}" "$i"  &&  mv ${mysql}/$i ${mysqlerr}/$i ) 2>&1 &
  waiting "${dwmc}" "${num}";
done