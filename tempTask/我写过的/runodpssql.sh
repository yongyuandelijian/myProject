#!/bin/bash  JC_GSZJ/J1_JSSJ/SC_JC_GSZJ/sql/
#####################################################################################################
#author:aaa
#create-time:2020-08-25
#function:执行指定文件夹内的odps sql
# 参数，文件路径
# 用法：sh runodpssql.sh JC_GSZJ/BJYH/SC_JC_GSZJ/sql/
#####################################################################################################

odpscmd="/home/admin/odps/bin/odpscmd"
path=$1  # 传入需要执行的路径
# path="GSZJ/BJYH/SC_JX_GSZJ/sql/"
if [ -d "${path}" ]
then
# 获取内容进行读取，执行
for file in `ls ${path}`
do
if [ -f ${file} ] then
	sql_command=`cat ${path}${file}`
	echo "正在执行的sql是：${sql_command}"
	${odpscmd} --project="SC_JC_GSZJ" -e "${sql_command}"  >templog/${file}.log
fi
done
else
echo "${path} not exists,please check !!!";
fi;
