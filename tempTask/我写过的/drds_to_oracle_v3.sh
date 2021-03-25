#!/bin/bash
# 功能增量：从drds库（sjfwpt），增量同步数据到oracle库 
# 参数：表名称 (hx_dm_zdy_dm_gy_swjg)  多主键测试表，单主键测试表 LS_HX_DJ_DJ_NSRXX
# 用法：sh makejson_drds_oracle.sh
# 思路：先利用sfq抽取二十分钟之前的数据增量到临时表，然后再使用oracle的更新思路进入到最终表
# 修改：所有参数都已经给定用来在crontab中测试准确性稳定性  sh /home/admin/work_space/lpc/makejson_drds_oracle.sh

# 定义普通参数
src_tabname="LS_HX_DJ_DJ_NSRXX"
curdir="/home/admin/work_space/lpc"
curtime=$(date "+%Y%m%d%H%M")
cyctime1=${curtime:0:8}
cyctime2=${curtime:8:4}
# 由于源段数据到来的延迟超过十几分钟，所以只能延迟20分钟获取数据
pretime=`date -d "${cyctime1} ${cyctime2} 40 minute ago" +%Y%m%d%H%M`
uptime=`date -d "${cyctime1} ${cyctime2} 20 minute ago" +%Y%m%d%H%M`
src_tabname=$(echo "${src_tabname}"|tr 'a-z' 'A-Z')
tar_tabname=$(echo "${src_tabname}"|tr 'a-z' 'A-Z') 	# 目标表先认为是一致的
ls_tabname=$(echo ${tar_tabname}|sed 's/^/n_/g'|tr 'a-z' 'A-Z')	# 临时表用来
# 定义目录
jsondir="${curdir}/${curtime}/json"
logdir="${curdir}/${curtime}/log"
if [ ! -d "${jsondir}" ]; then mkdir -p "${jsondir}"; echo "目录不存在已创建"; fi;
if [ ! -d "${logdir}" ]; then mkdir -p "${logdir}"; echo "目录不存在已创建"; fi;

#oracle sqlplus环境变量
################################################################################
export JAVA_HOME=/home/admin/jdk/jdk
export ORACLE_HOME=/home/admin/client/oracle
export LD_LIBRARY_PATH=${ORACLE_HOME}/lib
export PATH=$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH
################################################################################


# 获取源段drds数据库信息
sql_getdrds="select concat(dbname,'|',ip,'|',port,'|',username,'|',password) from datasource_conf_drds0 where name = 'ZR_SCK';"
drdsinfo=$(mysql -h127.0.0.1 -P3306 -u11111 -p22222 -D rcount -N -e "${sql_getdrds}")
if [[ $? -ne 0 ]];then echo "获取drds数据库信息失败！！！";exit 1;fi
if [ ${#drdsinfo} -le 0 ];then echo "未获取drds数据库信息！！！";exit 1;fi
echo "============== drds连接信息是： ${drdsinfo} =============="
src_dbname=`echo ${drdsinfo}  |awk -F "|" '{print $1}'`
src_ip=`echo ${drdsinfo}|awk -F "|" '{print $2}'`
src_port=`echo ${drdsinfo}|awk -F "|" '{print $3}'`
src_username=`echo ${drdsinfo}|awk -F "|" '{print $4}'`
src_password=`echo ${drdsinfo}|awk -F "|" '{print $5}'`

# 获取源段列
src_col=$(mysql -h${src_ip} -P${src_port} -u${src_username} -p${src_password} -D ${src_dbname} -N -e "desc ${src_tabname};" |awk '{printf $1","}'|sed 's/.$//g')
echo "源段列是：${src_col}"

# 获取源端主键
# mysql -h99.15.55.148 -P3306 -usjjc -pSjjc1234 -D sjjc -N -e "desc hx_dm_zdy_dm_gy_swjg;" |awk '{if($4=="PRI") printf $1","}'|sed 's/.$//g'
pk_col=$(mysql -h${src_ip} -P${src_port} -u${src_username} -p${src_password} -D ${src_dbname} -N -e "desc ${src_tabname};" |awk '{if($4=="PRI") printf $1","}'|sed 's/.$//g')
echo "主键列是：${pk_col}"

# 目标端oracle 数据库信息
tar_dbname="gszjdb"
tar_ip="99.15.49.117"
tar_port="1521"
tar_jdbc="99.15.49.117:1521/gszjdb"
tar_username="hx_odps"
tar_password="odps123"


# 获取目标表列
# source_tab=`sqlplus -S ${tar_username}/\"${tar_password}\"@${tar_jdbc} <<END
# set heading off
# set feedback off
# set pagesize 0
# set linesize 30000
# set verify off
# set echo off
# select t1.owner || '_' || t1.TABLE_NAME || '|' || t1.owner || '|' || t1.TABLE_NAME || '||'
#   from sys.dba_tab_cols t1
#  where t1.owner || '_' || t1.TABLE_NAME = upper('${tar_tab}')
#  group by t1.owner || '_' || t1.TABLE_NAME || '|' || t1.owner || '|' ||
# 		  t1.TABLE_NAME || '||';
# quit;
# END`


tar_col=`sqlplus -S ${tar_username}/\"${tar_password}\"@${tar_jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
select t.column_name from sys.dba_tab_columns t  where t.owner = upper('${tar_username}') and t.table_name=upper('${src_tabname}');
quit;
END`

tar_col=$(echo "${tar_col}"|awk '{printf $1","}'|sed 's/.$//g')  # 提取变量未写引号导致获取的值是多行
if [ ${#tar_col} -le 0 ]; then echo "${src_tabname}在目标端未找到对应的列信息！！！"; exit -1; fi;
echo "目标列是：${tar_col}"

# 如果源段和目标端不一致处理为一致
final_col=""
for temp_tar in $(echo "${tar_col}"|sed 's/,/ /g')
do
temp_col=null
for temp_src in $(echo "${src_col}"|sed 's/,/ /g')
do
if [ "${temp_src}"=="${temp_tar}" ]; then
temp_col="${temp_tar}"
fi;
done
if [ ${#final_col} -lt 1 ]; then final_col="${temp_col}"; else final_col="${final_col} ${temp_col}"; fi;
done

echo "最终列是：${final_col}"
final_col=$(echo "${final_col}"|sed 's/^/"/g'|sed 's/ /","/g'|awk '{printf $0}'|tr '[a-z]' '[A-Z]'|sed 's/$/"/g')
datax_col=$(echo "${tar_col}"|sed 's/^/"/g'|sed 's/,/","/g'|awk '{printf $0}'|tr '[a-z]' '[A-Z]'|sed 's/$/"/g')

datax_where="sfq>='${pretime}' and sfq<'${uptime}'"	# 获取where 条件 drds不需要配置主键切分
#======================================== 上面插入临时表，然后和目标表进行merge into ========================================#
# 获取需要更新的列，如果主键存在，目标列逐个去除主键
pk_num=`echo ${pk_col}|awk -F ',' '{print NF}'`  # 获取到主键个数

# 如果多主键每个主键列的拼接
join_part=""
temp_col="${tar_col}"
if [ ${pk_num} -gt 1 ]
then
for pk_temp in $(echo "${pk_col}"|sed 's/,/ /g')
do
temp_col=$(echo "${temp_col}"|sed "s/\<${pk_temp}\>//g")	# 精确匹配防止有些近似的列被去除
join_temp=$(echo "a.${pk_temp}=b.${pk_temp}")
# 如果大于0则需要拼接and否则不需要
if [ ${#join_part} -gt 1 ];then join_part="${join_part} and ${join_temp}"; else join_part="${join_temp}";fi;
done
elif [ ${pk_num} -eq 1 ]; then
join_part=`echo "a.${pk_col}=b.${pk_col}"`
temp_col=`echo "${tar_col}"|sed "s/\<${pk_col}\>//g"`	# 精确匹配防止有些近似的列被去除
fi
update_col=$(echo "${temp_col}"|sed 's/,,/,/g')	# 将替换完主键的部分符号消除
echo "要更新的列是：${update_col}"
# 拼接update的列
merge_updatecol=""
for temp_col in $(echo ${update_col}|sed 's/,/ /g')
do
if [ ${#merge_updatecol} -gt 1 ]; then merge_updatecol="${merge_updatecol},a.${temp_col}=b.${temp_col}"; else merge_updatecol="a.${temp_col}=b.${temp_col}"; fi;
done

# 拼接insert和value的列
merge_insertcol=$(echo "${tar_col}"|sed 's/,/,a./g'|sed 's/^/a./g')
merge_valuescol=$(echo "${tar_col}"|sed 's/,/,b./g'|sed 's/^/b./g')

# 添加到postSql
merge_sql="merge into ${tar_tabname} a USING (select ${tar_col} from ${ls_tabname}) b on (${join_part}) when matched then update set ${merge_updatecol} when not matched then insert (${merge_insertcol}) values(${merge_valuescol})"
echo "合并sql是：${merge_sql}"

# 拼接json  移除列        \"splitPk\" : \"\", drds的源段不需要配置这个否则会出现提示
speed="5"
core="
\"core\":{
  \"transport\":{
    \"channel\":{
      \"speed\":{
        \"byte\":\"-1\",
        \"record\":\"-1\"
      }
    }
  }
},
"
json="{
${core}
\"job\": {
  \"content\":[
    {
      \"reader\":{
        \"name\": \"drdsreader\",
        \"parameter\":{
		\"username\": \"${src_username}\",
		\"password\": \"${src_password}\",
        \"column\":[
		    ${final_col}
		],
		\"where\": \"${datax_where}\",
        \"connection\" : [
			{
				\"table\": [
					\"${src_tabname}\"
				],
				\"jdbcUrl\": [
					\"jdbc:mysql://${src_ip}:${src_port}/${src_dbname}?useUnicode=true&characterEncoding=utf-8\"
				]
			}
		  ]
        }
     },    
     \"writer\": {
            \"name\":\"oraclewriter\",
            \"parameter\":{
                \"column\":[
                    ${datax_col}
                ],
                \"preSql\":[
                    \"truncate table ${ls_tabname}\"
                ],
				\"postSql\":[
                    \"${merge_sql}\"
                ],
                \"connection\":[
                    {
                    \"jdbcUrl\": \"jdbc:oracle:thin:@${tar_jdbc}\",
                    \"table\":[
                    \"${ls_tabname}\"
                    ]
                    }
                ],
                \"batchSize\":2048,
                \"password\":\"${tar_password}\",
                \"username\":\"${tar_username}\",
                \"where\":\"\"
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

echo "${json}" >"${jsondir}/${src_tabname}.json"
python /home/admin/datax3/bin/datax.py  --jvm="-Xms2g -Xmx8g"  ${jsondir}/${src_tabname}.json  >${logdir}/${src_tabname}.log 2>&1
err=`cat ${logdir}/${src_tabname}.log|grep 'com.alibaba.datax.common.exception' |wc -l`
if [ "${err}" -gt 0 ]; then echo "执行json失败！！！"; cat ${logdir}/${src_tabname}.log|grep 'com.alibaba.datax.common.exception'; exit -1; fi;