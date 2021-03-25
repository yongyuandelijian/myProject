#!/bin/bash
dwmc=$1
##定义conf文件存放路径
oldconfloc="/home/admin/version/${dwmc}/datasource.conf_old" 
confloc="/home/admin/version/${dwmc}/datasource.conf"
mv ${confloc} ${oldconfloc}
if [ $? -ne 0 ];then echo "bake up old conf err";exit 1; fi
##定义mysql函数
mysqlcmd()
{
sql="$1"
#rcount（v3）配置
jdbc=
sdata=`mysql $jdbc -N -e "${sql}"`
if [[ $? -ne 0 ]];then echo "select rds error";exit 1;fi
echo $sdata
}
sql="select concat(db,'|',jdbc,'|',user,'|',pass) from ffk_datasource_conf where dwmc = '${dwmc}';"
echo ${sql}
mysqlcmd  "${sql}"
#获取最新的数据库连接信息
db=`echo ${sdata}  |awk -F "|" '{print $1}'`
jdbc=`echo ${sdata}|awk -F "|" '{print $2}'`
user=`echo ${sdata}|awk -F "|" '{print $3}'`
pass=`echo ${sdata}|awk -F "|" '{print $4}'`
echo -e "#####分发库配置信息#####\ndb=\"${db}\"\njdbc=\"${jdbc}\"\nuser=\"${user}\"\npass=\"${pass}\"" > ${confloc}