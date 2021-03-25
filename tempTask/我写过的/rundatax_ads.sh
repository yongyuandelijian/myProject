#!/bin/bash
# 功能: 运行推送ads的json
# 参数：bizdate (20200831) num  并发数() dwmc (GSZJ_2) 用来读取json
# 用法：sh rundatax.sh 20200831 5 GSZJ_2
# 时间：aaa 20200928
################################################################################
#oracle sqlplus环境变量
################################################################################
#oracle sqlplus环境变量
################################################################################
export ORACLE_HOME=/opt/oracle
export LD_LIBRARY_PATH=/opt/oracle/lib
export PATH=$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH
################################################################################
#增量日期
bizdate=$1
#作业并发度
num=$2
#单位名称
dwmc=$3
mydir=`pwd`

testdir="${mydir}/${dwmc}"
if [ ! -d "${mydir}/${dwmc}" ]; then mkdir "${mydir}/${dwmc}";fi;

if [[ ${bizdate} ]];then
  myjson="${testdir}/${bizdate}/json"
  mylog="${testdir}/${bizdate}/log"
  if [ ! -d "${testdir}/${bizdate}" ]; then mkdir "${testdir}/${bizdate}";fi;
  if [ ! -d "${testdir}/${bizdate}/json" ]; then mkdir "${testdir}/${bizdate}/json";fi;
  if [ ! -d "${testdir}/${bizdate}/log" ]; then mkdir "${testdir}/${bizdate}/log";fi;
fi


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
    sleep 3;
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

#执行
>${mylog}/${dwmc}
for sstable in `ls ${myjson}|sed 's/.json//g'`
do
  echo $sstable
  loging "1" "${dwmc}" "$sstable";
sleep 0.2;
echo "/home/admin/datax3/bin/datax.py --jvm="-Xms1g -Xmx4g" ${myjson}/${sstable}.json >${mylog}/${sstable}"
nohup python /home/admin/datax3/bin/datax.py --jvm="-Xms2g -Xmx8g" ${myjson}/${sstable}.json >${mylog}/${sstable} && loging "2" "${dwmc}" "$sstable" || loging "3" "${dwmc}" "$sstable" 2>&1 &
  waiting "${dwmc}" "${num}";
done
sleep 0.5;
waiting "${dwmc}";
echo "----------------------------------------------------------------------------"

exit 0
