#!/bin/bash
# 功能: 将指定的表从mysql抽取到odps
# 参数： 业务日期 bizdate 表名称从任务名称进行获取，任务名称是odps表名称  (dwide_node_def)
# 李鹏超： 20201204

# 需要的参数准备
bizdate=$1
src_table="node_def"
tar_table="dwide_node_def"
mydir=`pwd`

################################ odps配置 ################################################
odpsServer="http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api" #ODPS 的 endpoint 
tunnelServer="http://dt.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn"        #ODPS 的 endpoint  
odpsaccessId="yXKpKuN0xKF5MLpK"                                            #ODPS 的 accessid 
odpsaccessKey="1glCWzC8XkTT3BSpoY9NkYMibQslxB"                             #ODPS 的 accesskey 
odpscmd='/home/admin/client/odps/bin/odpscmd --endpoint=${odpsServer} -u ${odpsaccessId} -p ${odpsaccessKey}'

################################ 源端数据库配置 ################################################
jdbc="mysql://99.13.222.50:3306/dwide?useUnicode=true&characterEncoding=utf-8"
user="systemdata"
pass="systemdata_0705"
sspk="node_id"
#列的字符均被定义为小写
sselect="node_id,node_name,is_stop,description,para_value,priority,start_effect_date,end_effect_date,cron_express,owner,resgroup_id,baseline_id,app_id,create_time,create_user,last_modify_time,multiinst_check_type,cycle_type,dependent_type,last_modify_user,dependent_data_node,input,output,datax_file_id,datax_file_version,re_run_able,file_id,task_rerun_time,task_rerun_interval,ext_config,start_right_now"
##把表的列变成json需要的格式
sselect=`echo -n $sselect|awk '{gsub(/,/,"\",\"",$0);print "\""$0"\""}'`

swhere=''  # 这个配置先冗余，防止以后需要
################################################################################ 
#ODPS 配置
################################################################################ 
project="sc_jx_gszj"
partition=${bizdate}
truncate="true"

################################ json ################################################
json="{
\"job\": {
  \"content\":[
    {
      \"reader\":{
        \"name\":\"mysqlreader\",
        \"parameter\":{
          \"column\":[${sselect}
          ],
          \"connection\":[
            {
              \"jdbcUrl\":[
                \"jdbc:${jdbc}\"
              ],
              \"table\":[
                \"${src_table}\"
              ]
            }
          ],
          \"fetchSize\":1024,
          \"password\":\"${pass}\",
          \"splitPk\":\"${sspk}\",
          \"username\":\"${user}\",
          \"where\":\"${swhere}\"
        }
      },
       \"writer\":{
         \"name\":\"odpswriter\",
         \"parameter\":{
           \"accessId\":\"${odpsaccessId}\",
           \"accessKey\":\"${odpsaccessKey}\",
           \"column\":[${sselect}
           ],
           \"odpsServer\":\"${odpsServer}\",
           \"partition\":\"rfq=${partition}\",
           \"project\":\"${project}\",
           \"table\":\"${tar_table}\",
           \"truncate\":${truncate},
           \"tunnelServer\":\"${tunnelServer}\"
         }
       }
    }
  ],
  \"setting\":{
    \"errorLimit\":{
    \"record\":0
     },
    \"speed\":{
      \"channel\":1
    }
  }
 }
}"
#列的字符均被定义为大写，所有的关键字在这里做转换
echo -e "$json">${mydir}/${tar_table}.json
################################################################################
#执行数据同步作业
################################################################################
python /home/admin/datax3/bin/datax.py ${mydir}/${tar_table}.json
if [[ $? -ne 0 ]];then echo "执行json失败！！！";exit 1;fi

#清理一周前的分区 先不需要
# bbizdate=`date -d "${bizdate} 45 days ago" +"%Y%m%d"`
# if [ "$bbizdate" ];then
# dropsql="alter table ${project}.${tar_table} drop if exists partition (rfq=${bbizdate}); "
# ${odpscmd} --project=${project} -e "${dropsql}"
# if [[ $? -ne 0 ]];then echo "error";exit 1;fi 
# fi
exit 0