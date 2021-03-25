#!/bin/bash
# 功能：从北京云odps kf_jc_gszj，同步对比出的差异数据到drds库（sjjc 北京云在线库）
# 参数：1 odps表名称（l_hx_dj_dj_nsrxx）  2 bizdate （20201221） bizdate 用于指定存储在odps中的分区
# 用法：sh odpstodrds.sh cy20201222 l_hx_dj_dj_nsrxx
# 思路：将上一步的差异分区数据插入或者替换到drds》》》不是覆盖

# 需要的参数准备
bizdate=$1
sourceTable=$2
targetTable=`echo ${sourceTable}|sed 's/^l_//g'`
projectname='KF_JC_GSZJ'  # 当前是固定的，如果需要可以进行传参


# 处理目录和一些必要的检查
if [ $# -ne 2 ] || [ ${#bizdate} -ne 8 ] || [ -z ${tablelist} ]
then
echo "参数个数和要求的2个不匹配或者是日分区参数不是要求的8位，当前输入的参数是【$*】请核对后再进行操作！！！"; 
exit -1; 
fi;  # 必须符合参数要求

#临时文件夹 如果有先提示清理 rm -rf ${bizdate}
if [ -d ${bizdate} ]
then
read -p "${bizdate}目录已经存在，是否进行清理?（y/n）" huifu
if "${huifu}"="y" || "${huifu}"="Y"
then
rm -rf ${bizdate}
if [ $? ne 0 ]; then echo "目录清理完毕"; else echo "清理目录失败"; fi;
fi;

jsondir="${bizdate}/json"
mylog="${bizdate}/log"
if [ ! -d "${jsondir}" ]; then mkdir -p "${jsondir}";fi;
if [ ! -d "${mylog}" ]; then mkdir -p "${mylog}";fi;


# 目标端北京云odps链接信息
tunnelServer="http://dt.cn-beijing-gjsw-d01.odps.bjops.cloud.tax"
odpsServer='http://service.cn-beijing-gjsw-d01.odps.bjops.cloud.tax/api'
odpsaccessId='MfEPL30xpEODxw3U'
odpsaccessKey='UgP8mJmLNb0ZlSdo4BIRwuS86X2PPB'
odpscmd="/home/admin/client/odps/bin/odpscmd --endpoint=${odpsServer} -u ${odpsaccessId} -p ${odpsaccessKey}"


# 源端drds链接信息
src_dbname='sjjc'
src_ip='100.63.137.163'
src_port='3306'
src_username='sjjc'
src_password='Sjjc1234'


# 创建有名管道 预留
# [ -e /tmp/fd1 ] || mkfifo /tmp/fd1
# exec 3<>/tmp/fd1  #创建文件描述符，以可读(<)可写(>)的方式关联管道文件，这时候文件描述符3就有了有名管道文件的所有特性
# rm -rf /tmp/fd1   #关联后的文件描述符拥有管道文件的所有特性，所以这时候管道文件可以删除，我们留下文件描述符来用即可
# 
# for ((i=1;i<=3;i++))
# do 
#    echo >&3     #&3代表引用文件描述符3，这条命令代表往管道里面放入了一个"令牌"
# done

TarCols=`mysql -h${src_ip} -P${src_port} -u${src_username} -p${src_password} -D ${src_dbname} -N -e "desc ${targetTable};"|awk '{printf $1","}'|sed 's/.$//g'|sed 's/,/","/g'|sed 's/^/"/g'|sed 's/$/"/g' |tr 'a-z' 'A-Z'|sed 's/ //g'`

#==================================== 生成json ====================================
{
core="
\"core\":{
  \"transport\":{
    \"channel\":{
      \"speed\":{
        \"byte\":\"-1\",
        \"record\":\"-1\"
     }  }
  }
},
"
json="{
${core}
\"job\": {
  \"content\":[
    {
      \"reader\":{
        \"name\":\"odpsreader\",
		
        \"parameter\":{
		 \"accessId\":\"${odpsaccessId}\",
           \"accessKey\":\"${odpsaccessKey}\", 
		   \"odpsServer\":\"${odpsServer}\",
           \"partition\":[\"rfq=${bizdate}\"],
           \"project\":\"${projectname}\",
           \"table\":\"${sourceTable}\",
           \"tunnelServer\":\"${tunnelServer}\",
          \"column\":[
		             ${TarCols}
          ]
        }
      },
       \"writer\":{ 
		 \"name\":\"drdswriter\",
        \"parameter\":{
          \"column\":[
		             ${TarCols}
          ],
          \"connection\":[
            {
              \"jdbcUrl\":
                \"jdbc:mysql://${src_ip}:${src_port}/${src_dbname}?useUnicode=true&characterEncoding=utf-8\"
              ,
              \"table\":[
                \"${targetTable}\"
              ]
            }
          ],
		  \"writeMode\":\"replace\",
		  \"batchSize\":\"1024\",
          \"password\":\"${src_password}\",
          \"username\":\"${src_username}\"

        }
       }
    }
  ],
  \"setting\":{
    \"errorLimit\":{
    \"record\":0
    },
    \"speed\":{
      \"channel\":10
    }
  }
 }
}"
echo ${json} >&1 |tee -a ${jsondir}/${sourceTable}.json
python /home/admin/datax3/bin/datax.py --jvm="-Xms2g -Xmx8g" ${jsondir}/${sourceTable}.json 
if [[ $? -ne 0 ]];then echo "执行【${sourceTable}.json】失败";exit 1;fi
