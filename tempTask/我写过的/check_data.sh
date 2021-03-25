#!/bin/bash
#===============================================================================
#          FILE:  check_data_test.sh
#   DESCRIPTION:  检测延时时间，写入RDS分析
#        AUTHOR:  wuyuezhen
#        MODIFY:  wuyuezhen
#       COMPANY:  css.com.cn
#       VERSION:  1.1
#       CREATED:  2018-05-08 21:12:13
#    LASTMODIFY:  2018-12-24 14:53:00
#===============================================================================
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
dwmc=$1
bizDate=$2
################################################################################
#oracle sqlplus环境变量
################################################################################
export ORACLE_HOME=/home/admin/client/oracle
export LD_LIBRARY_PATH=/home/admin/client/oracle/lib
export PATH=/home/admin/odpscmd/bin:$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH
################################################################################
#rds预生产配置
#######################################################################
hostname1="127.0.0.1"
port1="1111"
username1="1111"
password1="2222"
dbanme1="3333"
tablename1="4444"
#######################################################################
#rds生产配置
#######################################################################
dbanme="1111"                                                    #
hostname="127.0.0.1"                                               #
username="2222"                                               #
password="3333"                                           #
port="4444"                                                           #
tablename="5555"                                             #
#######################################################################
#rcount（v3）配置                                                     #
#######################################################################
rdbanme=1111                                                        #
rhostname=127.0.0.1                                               #
rusername=2222                                                      #
rpassword=3333                                                      #
rport=4444                                                            #
####################################################################### 
odpscmd="/home/admin/client/odps/bin/odpscmd --endpoint=http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api -u yXKpKuN0xKF5MLpK -p 1glCWzC8XkTT3BSpoY9NkYMibQslxB"
#source /home/admin/version/${dwmc}/datasource.conf
#修改数据源的获取方式 modi by yinqiang 20181120
dbsql="select concat(db,'|',jdbc,'|',user,'|',pass) from datasource_conf where dwmc = '${dwmc}' and sysname = 'HX_ZG';"
echo ${dbsql}
datasource=`mysql -h${rhostname} -P${rport} -u${rusername} -p${rpassword} -D ${rdbanme} -N -e "${dbsql}"`
if [[ $? -ne 0 ]];then echo "select rds error";exit 1;fi
db=`echo ${datasource}  |awk -F "|" '{print $1}'`
jdbc=`echo ${datasource}|awk -F "|" '{print $2}'`
user=`echo ${datasource}|awk -F "|" '{print $3}'`
pass=`echo ${datasource}|awk -F "|" '{print $4}'`
ii=0
#格式：201805081954 201805081954 +00 00:00:00
#第一个参数为oracle数据库当前的系统时间，第二个参数为系统时间与延迟的差
SQL="select to_char(sysdate,'yyyymmddhh24mi') as c1,to_char(sysdate-substr(value,2,2)-numtodsinterval(substr(value,5,2),'hour')-numtodsinterval(substr(value,8,2),'minute'),'yyyymmddhh24mi') as c2,value from V\$dataguard_stats where name='apply lag';"
while true
do
OK=`sqlplus -S ${user}/${pass}@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
$SQL
quit;
END`
#如果退出状态不为0，输出信息，oracle数据库连接异常
if [ $? -ne 0 ];then echo "oracle connected error";exit 1;fi
ii=$[ii+1]
echo "--------"
echo "尝试连接 ${ii} 次 :$OK"

#ys_kssj（oracle延时开始时间）为OK的第二个参数：201805081954
ys_kssj=`echo $OK|awk '{print $2}'`
#ys_ksrq（oracle延时开始日期）取前8位
ys_ksrq=${ys_kssj:0:8}
#ys_jssj（oracle延时结束时间）为OK的第一个参数：201805081954
ys_jssj=`echo $OK|awk '{print $1}'`
#yssc（oracle延时时长）为OK的第四个参数:00:00:00
yssc=`echo $OK|awk '{print $3" "$4}'`
#监控时间：20180508201209，linux生产服务器当前时间
jksj=`date +"%Y%m%d%H%M%S"`
#业务日期+2天+9小时
bizdate29=`date -d "${bizDate} 56 hours" "+%Y%m%d%H%M%S"`
bizdate30=`date -d "${bizDate} 58 hours" "+%Y%m%d%H%M%S"`

#第一次业务日期与延迟计算后的时间比较，如果业务日期小，则无延迟作业可以运行
if [[ $ii -eq 1 ]];then
	#如果业务日期小于延时开始时间
    if [[ $bizDate -lt $ys_ksrq ]];then echo "该业务日期下作业可以运行";break;
	#第一次业务日期与延迟计算后的时间比较，如果业务日期大，则记录延迟的时间
	#如果业务日期大于等于延时开始时间，记录延时时间
	else  
	#延时开始时间赋值
	yskssj=$ys_kssj
	#延时时长赋值
	sc=$yssc
	#监控时间赋值
	jk=$jksj
	echo "该业务日期下有小于2天的延迟情况，写入RDS"
	SQL1="insert into t_dsj_fbkysjc_new(ys_kssj,ys_jssj,yssc,jcsj,rfq,dwmc,jcsj_9,yssc_9) values('${yskssj}','','${sc}','${jk}','${bizDate}','SC_JX_${dwmc}','','');"
	echo ${SQL1}	
	mysql -h${hostname} -P${port} -u${username} -p${password} -D ${dbanme} -e "${SQL1}"
	mysql -h${hostname1} -P${port1} -u${username1} -p${password1} -D ${dbanme1} -e "${SQL1}"
	fi
#第二次开始业务日期与延迟计算后的时间比较，如果业务日期小，则无延迟作业可以运行
elif [[ $bizDate -lt $ys_ksrq ]];then 
	echo "该业务日期下作业可以运行";
	SQL2="update t_dsj_fbkysjc_new set ys_jssj='${ys_jssj}' where rfq='${bizDate}' and dwmc='SC_JX_${dwmc}';"	
	echo ${SQL2}
	mysql -h${hostname} -P${port} -u${username} -p${password} -D ${dbanme} -e "${SQL2}"
	mysql -h${hostname1} -P${port1} -u${username1} -p${password1} -D ${dbanme1} -e "${SQL2}"
	break;
#如果业务日期大于等于延时开始日期，并且监控时间大于业务日期+2天+9小时，进行更新RDS操作
elif [[ $bizDate -ge $ys_ksrq && $jksj -ge $bizdate29 && $jksj -le $bizdate30 ]];then
	echo "该业务日期下有超过2天的延迟情况，写入RDS"
	SQL3="update t_dsj_fbkysjc_new set jcsj_9='${jksj}',yssc_9='${yssc}' where rfq='${bizDate}' and dwmc='SC_JX_${dwmc}';"
	echo ${SQL3}	
	mysql -h${hostname} -P${port} -u${username} -p${password} -D ${dbanme} -e "${SQL3}"
	mysql -h${hostname1} -P${port1} -u${username1} -p${password1} -D ${dbanme1} -e "${SQL3}"
	#延迟时间超过2天+9小时，睡眠1个小时
	sleep 3600;
fi
#第二次开始开始业务日期与延迟计算后的时间比较，如果业务日期大，则休眠5分钟
sleep 300;
done
exit 0
