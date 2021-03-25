#!/bin/bash
# 功能描述：根据表单生成从odps到ads推数据的json   使用到的文件 tablist 里面需要用到的格式 (SC_ZJ_GSZJ_2|ZJ_SWJG_DJ_XBDJHS_BY_HZ|本期新办登记户数汇总|qxjswjg_dm)
# 参数：1 bizdate (20200831)  2 dwmc (GSZJ_2) 用来创建文件夹的时候使用
# 用法:sh makejson.sh 20200831 GSZJ_2
# 修改时间：aaa 20200928
mydir=`pwd`
bizDate=$1
dwmc=$2
odpscmd='/home/admin/client/odps/bin/odpscmd --endpoint=http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api -u yXKpKuN0xKF5MLpK -p 1glCWzC8XkTT3BSpoY9NkYMibQslxB'
#临时文件夹

testdir="${mydir}/${dwmc}"
if [ ! -d "${mydir}/${dwmc}" ]; then mkdir "${mydir}/${dwmc}";fi;

if [[ ${bizDate} ]];then
  rm -rf ${testdir}/${bizDate}
  myjson="${testdir}/${bizDate}/json"
  mylog="${testdir}/${bizDate}/log"
  if [ ! -d "${testdir}/${bizDate}" ]; then mkdir "${testdir}/${bizDate}";fi;
  if [ ! -d "${testdir}/${bizDate}/json" ]; then mkdir "${testdir}/${bizDate}/json";fi;
  if [ ! -d "${testdir}/${bizDate}/log" ]; then mkdir "${testdir}/${bizDate}/log";fi;
else
  myjson="${testdir}/json"
  mylog="${testdir}/log"
  rm -rf ${testdir}/json
  rm -rf ${testdir}/log
  if [ ! -d "${testdir}/json" ]; then mkdir "${testdir}/json";fi;
  if [ ! -d "${testdir}/log" ]; then mkdir "${testdir}/log";fi;
fi
mylog="${testdir}/log"

#ODPS 配置          --下面部分都是 ODPS 配置的内容                             #
################################################################################ 
odpsServer="http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api"     #
tunnelServer="http://dt.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn"            #
odpsaccessId="yXKpKuN0xKF5MLpK"                                                #
odpsaccessKey="1glCWzC8XkTT3BSpoY9NkYMibQslxB"                                 #

# ads 配置
ads_url='quickbi-ysc-c7e3a660.cn-foshan-lhc-am338001-a.alicloud.its.tax.cn:10691'
ads_username='TiGFmfEFPp7zvGvs'
ads_password='gXimYLRulwZa8rBUOWlpybD200WVRL'
ads_schema='quickbi_ysc'

#创建有名管道
[ -e /tmp/fd1 ] || mkfifo /tmp/fd1
#创建文件描述符，以可读(<)可写(>)的方式关联管道文件，这时候文件描述符3就有了有名管道文件的所有特性
exec 3<>/tmp/fd1
#关联后的文件描述符拥有管道文件的所有特性，所以这时候管道文件可以删除，我们留下文件描述符来用即可
rm -rf /tmp/fd1

for ((i=1;i<=10;i++))
do 
   echo >&3     #&3代表引用文件描述符3，这条命令代表往管道里面放入了一个"令牌"
done

for x  in `cat ${mydir}/tablist`
do
read -u3
projectName=`echo ${x}|awk -F "|" '{print $1}'|tr '[A-Z]' '[a-z]'`
sourceTable=`echo ${x}|awk -F "|" '{print $2}'|tr '[A-Z]' '[a-z]'`
targetTable=`echo ${x}|awk -F "|" '{print $2}'|tr '[A-Z]' '[a-z]'`
echo "要推送的表是：${projectName}.${targetTable}"
{ 

initCols2=`${odpscmd} --project=${projectName} -e "desc ${sourceTable};"|grep -E 'bigint|string|boolean|double|datetime|decimal|Partition' | awk '{print $2}' | awk '{printf $0","}'`
allCols2=$(echo ${initCols2%%Partition*} | tr '[a-z]' '[A-Z]') 
allCols2=${allCols2%?} 
initTarCols=`echo ${allCols2}|awk '{gsub(/,/,"\",\"",$0);print "\""$0"\""}'`
echo ${initTarCols}

pk=`echo ${x}|awk -F"|" '{print $4}'`   # 分割主键已经给定
echo "PK is ${pk}"
if [[ ! -n ${pk} ]];then echo "$i have not found PK";exit 1;fi

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
           \"partition\":[\"rfq='${bizDate}'\"],
           \"project\":\"${projectName}\",
           \"table\":\"${sourceTable}\",
           \"tunnelServer\":\"${tunnelServer}\",
          \"column\":[
		             ${initTarCols}
          ]
        }
      },
       \"writer\":{
	    \"name\":\"adswriter\",
		 \"parameter\":{
		  \"writeMode\": \"load\",
		  \"url\": \"${ads_url}\",
		  \"schema\": \"${ads_schema}\",
		  \"table\": \"${targetTable}\",
          \"column\":[
		             ${initTarCols}
          ],
          \"username\": \"${ads_username}\",
		  \"password\": \"${ads_password}\",
          \"partition\": \"${pk}\",
		  \"overWrite\": true
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
echo ${json} > ${myjson}/${targetTable}.json
#python /home/admin/datax3/bin/datax.py --jvm="-Xms1g -Xmx4g" ${myjson}/${targetTable}.json > ${mylog}/${targetTable}.log 2>&1
   echo >&3                            #代表这一次命令执行到最后，把令牌放回管道
}&
done
wait

exec 3<&-                               #关闭文件描述符的读
exec 3>&-                               #关闭文件描述符的写
exit 0