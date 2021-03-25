#!/bin/bash
#####################################
#name: 文件完整性检测
#createtime :20180330 15:30
#lastmodifytime:20181211 15:10
#####################################
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
#####################################################################################################
bizdate=$1
dwmc=$2
date=`date -d "${bizdate} next-day" +"%Y%m%d"`
bbizdate=`date -d "${bizdate} 1 days ago" +"%Y%m%d"`
mothbizdate=`date -d "${bizdate} 30 days ago" +"%Y%m%d"`
mydir="/home/admin/oggdocuments/${dwmc}"
#create documents
if [ ! -d "/home/admin/oggdocuments" ]; then mkdir -p "/home/admin/oggdocuments";fi;
if [ ! -d "/home/admin/oggdocuments/${dwmc}" ]; then mkdir -p "/home/admin/oggdocuments/${dwmc}";fi;
if [ ! -d "${mydir}/addfilelist" ]; then mkdir -p "${mydir}/addfilelist";fi;

#1、查询rds的数据获取结果,判断前一天的文件是否传输完毕
##判断条件：当天的任务成功且文件标志有两个1个以上的OK
mysqlcmd="mysql -h99.13.220.242 -P3306 -urcount -prcount -Drcount -s"
odpscmd="/home/admin/client/odps/bin/odpscmd --project=sc_jc_gszj"
waiting()
{
      while true
            do
                ddlsql="select count(*) as result from odps_jobstatus t where substr(t.jobname,1,8) >= '${2}' and projectname = '${1}' and job_status = 'OK' and filesymbolhx = 'OK1' AND filename NOT LIKE '${bizdate}%'"
                result=`${mysqlcmd} -e "${ddlsql}"|grep -v result`
                echo ${result}
                if [[ ${result} -ge "1" ]];then break;fi
                sleep 5;
            done
}

#检测前一天的文案是否传输完毕
waiting ${dwmc} ${date}

echo "check_hx passed"
