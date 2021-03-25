#!/bin/bash
#####################################################################################################
#author:wlt
#create-time:2020-03-22
#function:get stuck mget taskid and rerun it regularly
# 李鹏超修改于20200922 为了防止出现任务出现重跑不可修复的问题时会一直向前回退的问题，增加获取task_inst_id后对名单任务状态的判断，如果要重跑的任务实际以及ok则不在重跑
#####################################################################################################
# 参数
# mydir="/home/zr_user/rerun_task"
mydir="/home/zr_user/work_space/lipengchao"
cyctime=`date +%Y%m%d%H%M`
ocyctime=`date  -d "7 day ago " +%Y%m%d%H%M`
# 数据库函数
mysqlcmd()
{
sql=$1
db=$2
if [ "${db}" == "rcount" ]
then
jdbc=	#rcount（v3）配置
elif [ "${db}" == "systemdata" ]
then
jdbc="";	#systemdata 配置
fi;
mysqlresult=`mysql ${jdbc} -N -e "${sql}"`
echo ${mysqlresult}
}
# 处理目录文件
if [ -e ${mydir}/rerun_taskid_${cyctime}.txt ]; then rm ${mydir}/rerun_taskid_${cyctime}.txt; fi;
#获取失败以及卡住任务的前置任务id
sql_gettaskid="
select tt.task_inst_id,tt.dw,tt.due_time from 
(select a.task_inst_id,right(b.name,4) dw,date_format(a.due_time,'%Y%m%d%H%i%S') due_time
from phoenix_task_inst a
inner join phoenix_app_config b on a.app_id = b.app_id 
inner join (select b.name,date_sub(a.due_time,INTERVAL  10 MINUTE) due_time
from phoenix_task_inst a,phoenix_app_config b
where a.app_id = b.app_id
and a.gmtdate >= timestampdiff(DAY,a.gmtdate,CURRENT_DATE()) <= 3
and a.gmtdate <= CURRENT_DATE 
and a.status not in ('1','6')
and b.project_env='PROD'
AND B.NAME LIKE 'SC_JX___ST'
and a.node_name = 'mget'
and timestampdiff(minute,begin_run_time,now()) > 50
and a.due_time < date_sub(now(),INTERVAL  10 MINUTE)
) c on c.name=b.name and a.due_time=c.due_time
where a.gmtdate <= CURRENT_DATE   and b.project_env='PROD' AND B.NAME LIKE 'SC_JX___ST' and a.node_name = 'mget'
union all 
select a.task_inst_id,right(b.name,4) dw,date_format(a.due_time,'%Y%m%d%H%i%S') due_time from phoenix_task_inst a
inner join phoenix_app_config b on a.app_id = b.app_id where a.gmtdate >= timestampdiff(DAY,a.gmtdate,CURRENT_DATE())<= 3 and a.gmtdate<= CURRENT_DATE and b.project_env='PROD' AND B.NAME LIKE 'SC_JX___ST' and a.node_name = 'mget' and a.status='5'
)tt order by tt.due_time; "

mysqlcmd "${sql_gettaskid}" systemdata |grep -v "\+-" |grep -v ^$ > ${mydir}/temp_${cyctime}.txt
if [[ -s  "${mydir}/temp_${cyctime}.txt" ]];then 
# 逐个去除状态已经OK的任务id
cat ${mydir}/temp_${cyctime}.txt|while read line;
do
rwid=`echo ${line} |awk '{print $1}'`
dw=`echo ${line} |awk '{print $2}'`
dssj=`echo ${line} |awk '{print $3}'`
sql_successtaskid="select count(1) sl from odps_jobstatus t where job_status='OK' and t.projectname='${dw}' and t.jobname='${dssj}'"
echo "过滤成功任务sql是: ${sql_successtaskid}"
isexists=`mysqlcmd "${sql_successtaskid}" "rcount"`
if [ ${isexists} -eq 0 ];then echo ${rwid}>>${mydir}/rerun_taskid_${cyctime}.txt; fi;   # 如果状态不是OK再存储到要重跑的任务清单中
done;
else
echo "No fail task at present"
fi;

#rerun fail task 
if [[ -s  "${mydir}/rerun_taskid_${cyctime}.txt" ]];then
	for i in `cat ${mydir}/rerun_taskid_${cyctime}.txt`;do curl -i -X PUT -H "Content-Type: application/json" "http://phoenix.alicloud.its.tax.cn/engine/2.0/tasks/${i}/rerun" -d ' {"opCode":"RERUN_BY_MANUAL","opSEQ":123456,"opUser":"068198"} ';done
	#if [[ $? -ne 0 ]];then echo "rerun task fail"; exit 1 ; fi 
	echo "rerun task success"
else
    echo "No fail task at present"
fi

#clear old files
echo ${ocyctime}
ofs=`ls -l ${mydir} |grep txt|awk '{print $9}' |awk -F '_' '{print $3}' |awk -F '.' '{print $1}'`
echo ${ofs}
for i in ${ofs}
do
	if [[ ${i} -lt ${ocyctime} ]];then
		echo "gonging to clean ${mydir}/rerun_taskid_${i}.txt"
		rm -rf ${mydir}/rerun_taskid_${i}.txt
	fi
done
