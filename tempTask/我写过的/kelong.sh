#!/bin/bash
#################################################################################
# ScriptName: kelong.sh

bizDate=$1
GMTDATE=`date -d "${bizDate} next-day" +"%Y%m%d"`
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
    wget -P ${tdir} http://sjjc.oss-cn-foshan-lhc-d01-a.ops.its.tax.cn/Tools/client.tar.gz && cd ${tdir} && tar -zxvf client.tar.gz -C ${tdir}
    if [[ $? -ne 0 ]];then echo "tar failed";rm -rf ${tdir}/client;else mkdir "${tdir}/chkend";fi
 fi
fi
mysqlcmd="mysql -h 99.13.222.50 -P3306 -usystemdata -psystemdata_0705 -Dsystemdata "
rcount="mysql -h99.13.220.242 -P3306 -urcount -prcount -Drcount"

#检查check_hx是否有问题
check="select right(b.name,4) as dwmc
from phoenix_task_inst a,phoenix_app_config b,phoenix_node_def c
where a.app_id=b.app_id
and a.node_def_id = c.node_def_id
and a.status  <> '6'
and c.node_name = 'check_hx'
and a.gmtdate = '${GMTDATE}'
order by gmtdate,b.name,status ;"
dwlist=`${mysqlcmd} -e "${check}"|grep -v dwmc`
echo ${dwlist}

#判断是否月初
if [[ ! -n  "${dwlist}" ]]; then echo "任务正常"
else
if [ ${GMTDATE:0-2} -ne "01" ]
then
for dw in ${dwlist}
do 
#获取失败的task_inst_id
chksql="select concat(a.task_inst_id,'|',b.name,'|',c.node_name,'|',a.status,'|',left(a.gmtdate,10)) as sum
from phoenix_task_inst a,phoenix_app_config b,phoenix_node_def c
where a.app_id=b.app_id
and a.node_def_id = c.node_def_id
and a.status  <> '6'
and c.node_type <> '2'
and b.name like 'sc_jx_${dw}'
and b.project_env='PROD'
and c.node_name not like 'n_ls_gs_%'
and (c.node_name like 'n_ls%' or c.node_name like 'sbxt%' or c.node_name like 'ls_zj_hcp_%' 
or c.node_name like 'pri_zj_hcp_%' or c.node_name like '%_clob' or c.node_name='check_hx' or c.node_name='makeconf'
or c.node_name='update_version_ls' or c.node_name='datax_oracle_to_odps')
and a.gmtdate = '${GMTDATE}'
order by gmtdate,b.name,status ; "

value=`${mysqlcmd} -e "${chksql}"`
value1=`echo $value|sed 's/sum//g'`
task_inst_id=`echo $value1|sed 's/ /\n/g'|awk -F '|' '{print $1}'`
dwmc=`echo $value1|sed 's/ /\n/g'|awk -F '|' '{print $2}'|awk -F '_' '{print $3}'`
gmtdate=`echo $value1|sed 's/ /\n/g'|awk -F '|' '{print $5}'|sed 's/\-//g'`
echo $task_inst_id
echo ${gmtdate}
#将镜像层的taskid置成功
for i in `echo $task_inst_id`; do curl -i -X PUT -H "Content-Type: application/json" "http://phoenix.alicloud.its.tax.cn/engine/2.0/tasks/${i}/setsuccess" -d ' {"opCode":"RERUN_BY_MANUAL","opSEQ":123456,"opUser":"068198"} ';done

#将失败的信息记录到rcount中
for i in  ${value1}
do
for j in  ${dwmc}
do
for k in ${gmtdate}
do
insert="insert into kelong (list,dwmc,gmtdate) values ('${i}','${j}','${k}');"
echo ${insert}
${rcount} -e "${insert}"
done
done
done

done

else
echo "月初不克隆"
fi #是否月初的if
fi #dwlist是否存在的if
