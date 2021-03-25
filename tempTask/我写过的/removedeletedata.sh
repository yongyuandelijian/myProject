#!/bin/bash
###############################备注说明###########################################################
# 功能：从处理好的分区去除删除的部分
# 参数：1 bizdate 日分区 2 dwmc 单位代码 3 基础层表名称 （ZJ_HCP_HCP_PJJG_YJ）
# 实现思路：1 从分发库获取指定单位表的全量主键到N表  
#			2 N表和基础层现有最新分区关联获取交集，这个时候结果不含被删除的部分(新增数据其他任务已经处理过)
#			3 在将或许后的交集插入到新分区中
# author：aaa
# date: 20201023
# 用法：nohup sh removedeletedata.sh 20201022 SXST >20201022.log 2>&1 &
###################################################################################################

# 如果参数个数不匹配则提示校验，防止带入造成较大问题
if [ $# -ne 3 ];then echo "\033[0;31;5m参数异常\033[0m; 要求的参数个数是bizdate和dwmc以及表名共3个，当前提供的参数是$#个，分别是$*请检查核对！！！"; exit -1; fi;

# 参数准备
odpsServer="http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api"     #
tunnelServer="http://dt.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn"            #
odpsaccessId="yXKpKuN0xKF5MLpK"                                                #
odpsaccessKey="1glCWzC8XkTT3BSpoY9NkYMibQslxB"   
# 传入参数
bizdate=$1
dwmc=$2
table_name=$3

dwmc=`echo ${dwmc}|tr 'a-z' 'A-Z'`
table_name=`echo ${table_name}|tr 'a-z' 'A-Z'`
tar_project="SC_JX_${dwmc}"
curdate=`date +"%Y-%m-%d"`

# 目录准备
curdir=`pwd`
json_dir="${curdir}/${dwmc}/${bizdate}/pk_json"  # 存储主键抽取json
log_dir="${curdir}/${dwmc}/${bizdate}/pk_log"	 # 存储主键抽取日志
sql_dir="${curdir}/${dwmc}/${bizdate}/sql"   	 # 存储获取数据sql
err_dir="${curdir}/${dwmc}/${bizdate}/err"  	 # 存储错误日志
if [ ! -d ${json_dir} ]; then mkdir -p "${json_dir}"; fi;
if [ ! -d ${log_dir} ]; then mkdir -p "${log_dir}"; fi;
if [ ! -d ${sql_dir} ]; then mkdir -p "${sql_dir}"; fi;
if [ ! -d ${err_dir} ]; then mkdir -p "${err_dir}"; fi;

# 固定参数
odpscmd="/home/admin/odps/bin/odpscmd --endpoint=http://service.cn-foshan-lhc-d01.odps.alicloud.its.tax.cn/api -u yXKpKuN0xKF5MLpK -p 1glCWzC8XkTT3BSpoY9NkYMibQslxB 
--project=${tar_project}"
endpoint='oss-cn-foshan-lhc-d01-a.alicloud.its.tax.cn'
accessid='yXKpKuN0xKF5MLpK'
accesskey='1glCWzC8XkTT3BSpoY9NkYMibQslxB'

# sqlplus环境变量
export ORACLE_HOME=/opt/oracle
export LD_LIBRARY_PATH=/opt/oracle/lib
export PATH=$JAVA_HOME/bin:$LD_LIBRARY_PATH:$PATH


#定义mysql函数
mysqlcmd()
{
db="$1"
sql="$2"
#rcount（v3）配置
jdbc="-h99.13.220.242 -P3306 -urcount -prcount -D rcount"
sdata=`mysql $jdbc -N -e "${sql}"`
if [[ $? -ne 0 ]];then echo "rcount excute failed";exit -1;fi
echo $sdata
}


# 获取数据源连接方式，云南实际测试 ffk_datasource_conf 这个表的配置是正确的 datasource_conf表的配置无法登陆,我们使用副本库
sql="select concat(db,'|',jdbc,'|',user,'|',pass) from fbk_datasource_conf where dwmc = '${dwmc}';"
echo ${sql}	
# echo `date "+%Y-%m-%d %H:%M:%S"`
mysqlcmd "rcount" "${sql}"
db=`echo ${sdata}  |awk -F "|" '{print $1}'`
jdbc=`echo ${sdata}|awk -F "|" '{print $2}'`
user=`echo ${sdata}|awk -F "|" '{print $3}'`
pass=`echo ${sdata}|awk -F "|" '{print $4}'`

# ================================ 检测下数据库延迟，如果副本库断开连接，则使用分发库进行连接,具体阀值暂时不能确定 ================================
chksql="
select to_char(sysdate,'yyyymmdd hh24:mi:ss')||'|',to_char(next_time,'yyyymmdd hh24:mi:ss')||'|',ceil((sysdate-next_time)*24*60) as yanshi  from v\$archived_log where applied = 'YES' and sequence#=(select max(sequence#) from v\$archived_log where applied = 'YES');"
date=`date "+%Y%m%d%H%M%S"`
echo "----------${date}----------------"

OracleData=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
${chksql}
quit;
END`
echo "${dwmc}延迟情况：${OracleData}"


# 创建有名管道，如果文件本身存在则删除否则创建会报错
if [ -e ./tempfile ]; then rm -f ./tempfile; fi;
mkfifo ./tempfile;
# 将文件描述符绑定管道文件，这个时候文件描述符就拥有了所有属性，删除管道文件，使用文件描述符即可
exec 3<> ./tempfile
rm -f ./tempfile;

# 创建令牌,我们的表比较大所以只允许同时跑2个
for i in $(seq 1 2)
do
echo >&3   # 每次输出一个换行符也就是一个令牌
done

# ================================ 按照表单准备数据 ================================
for tar_tab in `cat ${dwmc}.list`;
do
read -u3	# 读取一行获取一个令牌
{
ntable=`echo ${tar_tab} | sed 's/^/N_/g'`
# 获取表在oracle中的用户名和表名称（ 结果样式：HX_ZS_ZS_XHXX|HX_ZS|ZS_XHXX|| ）
source_tab=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set linesize 30000
set verify off
set echo off
select t1.owner || '_' || t1.TABLE_NAME || '|' || t1.owner || '|' || t1.TABLE_NAME || '||'
  from sys.dba_tab_cols t1
 where t1.owner || '_' || t1.TABLE_NAME = upper('${tar_tab}')
 group by t1.owner || '_' || t1.TABLE_NAME || '|' || t1.owner || '|' ||
		  t1.TABLE_NAME || '||';
quit;
END`
		
if [ $? -ne 0 ] || [[ ! ${source_tab} ]]
then
echo "${source_tab} get table info failed from source !!!" >&1 |tee -a ${err_dir}/check_table_err.txt;  # 如果没有参数就是每次都是覆盖插入
continue
fi;


# 获取原表
sourcetable=`echo ${source_tab}|awk -F '|' '{print $3}'`
owner=`echo ${source_tab}|awk -F '|' '{print $2}'`


# 获取列名称 shell脚本前面放空格标记格式容易导致异常，所以尽量不要写一大段，这样可读性差
source_col=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
select t.column_name from sys.dba_tab_columns t  where t.owner = upper('${owner}') and t.table_name=upper('${sourcetable}');
quit;
END`
	
source_col=`echo ${source_col}|sed 's/^/"/g'|sed 's/ /","/g'|awk '{printf $0}'|tr '[a-z]' '[A-Z]'|sed 's/$/"/g'`

if [[ ! ${source_col} ]]
then
echo "${sourcetable} get columns info failed from source !!!" >&1|tee -a ${err_dir}/check_table_err.txt
continue
fi;

# 寻找主键
pk_col=`${odpscmd} -e "desc ${tar_project}.${ntable};"|grep 'primary_key'|awk '{print $2}'|tr 'a-z' 'A-Z'`
# 针对多个或者没有的单独处理，大多数都是1个
pk_count=`${odpscmd} -e "desc ${tar_project}.${ntable};"|grep 'primary_key'|wc -l`
if [ ${pk_count} -gt 1 ]
then
# 暂时不在处理多个主键的情况列，因为多个主键拼接在一起，实际上还是不好校验，需要循环一个一个进来校验，如果后面需要处理多个主键的后续再从这里进行完善
pk_col=`echo ${pk_col}|awk '{printf $0","}'|sed 's/^/"/g'|sed 's/ /","/g'|sed 's/.$//g'|sed 's/$/"/g'`
elif [ ${pk_count} -eq 1 ]
then
pk_col=`echo ${pk_col}|sed 's/^/"/g'|sed 's/$/"/g'`
elif [ ${pk_count} -lt 1 ]
then
echo "${ntable} pk is not found";
continue;
fi;


echo "========================获取到的主键是:《${pk_col}》========================"

arr_col=$(echo ${pk_col}|sed 's/"//g'|sed 's/,/ /g')
for i in ${arr_col};
do
bd_result=`echo ${source_col} |grep ${i}|wc -l`
if [ ${bd_result} -lt 1 ]
then
echo "原端列${source_col} 中不含主键 ${pk_col}，请检查！！！" >&1|tee -a ${err_dir}/check_table_err.txt
continue
else
echo "${tar_tab} 源端和基础层表主键列比对通过。";
fi;
done;

swhere="SJTB_SJ<to_date('${curdate}','yyyy-mm-dd')"
temp_sl=`echo "${source_col}"|grep 'SJTB_SJ'|wc -l`
if [ ${temp_sl} -eq 0 ];then swhere=""; fi;
splitPk=$(echo ${pk_col}|awk -F ',' '{print $1}')
################################################### 拼接抽取全量主键JSON ###################################################
speed="10"
truncate="true"

json="{
\"job\": {
  \"content\":[
	{
	  \"reader\":{
		\"name\":\"${db}\",
		\"parameter\":{
		  \"column\":[${pk_col},
			\"sysdate\"
		  ],
		  \"connection\":[
			{
			  \"jdbcUrl\":[
				\"jdbc:oracle:thin:@${jdbc}\"
			  ],
			  \"table\":[
				\"${owner}.${sourcetable}\"
			  ]
			}
		  ],
		  \"fetchSize\":1024,
		  \"password\":\"${pass}\",
		  \"splitPk\":${splitPk},
		  \"username\":\"${user}\",
		  \"where\":\"${swhere}\"
		}
	  },
	   \"writer\":{
		 \"name\":\"odpswriter\",
		 \"parameter\":{
		   \"accessId\":\"${odpsaccessId}\",
		   \"accessKey\":\"${odpsaccessKey}\",
		   \"column\":[${pk_col},
			  \"yptetl_sj\"
		   ],
		   \"odpsServer\":\"${odpsServer}\",
		   \"partition\":\"rfq=${bizdate}\",
		   \"project\":\"${tar_project}\",
		   \"table\":\"${ntable}\",
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
	  \"channel\":${speed}
	}
  }
 }
}"
echo ${json} >${json_dir}/${tar_project}${ntable}.json

# 这里不能放到后台运行，否则会导致下一级无法获取到对应的条件
nohup python /home/admin/datax3/bin/datax.py  --jvm="-Xms2g -Xmx8g"  ${json_dir}/${tar_project}${ntable}.json  >&1 |tee -a ${log_dir}/${tar_project}${tar_tab}.log 2>&1
err_num=`cat ${log_dir}/${tar_project}${tar_tab}.log|grep 'com.alibaba.datax.common.exception' |wc -l`
if [ ${err_num} -gt 0 ]; then echo "执行抽取主键json失败！！！"; cat ${log_dir}/${tar_project}${tar_tab}.log|grep 'com.alibaba.datax.common.exception'; echo "${tar_project} 抽取主键json执行失败，请检查！！！" >&1|tee -a ${err_dir}/check_table_err.txt; continue; fi;


# 处理需要的列
sql_col=`echo ${pk_col}|sed 's/"//g'`	# 子查询查询列
ydzj_col=`echo ${sql_col}|sed 's/^/ydzj./g' |sed 's/,/,ydzj./g'`	# 源段主键列
sql_where=`echo ${sql_col}|sed 's/^/odps./g' |sed 's/,/ is null and odps./g'|sed 's/$/ is null/g'`	# where条件

# 获取到on的关联条件
arr_col=`echo ${sql_col}|sed 's/,/ /g'`
sql_on=`for i in ${arr_col};do echo "odps.${i}=ydzj.${i} "; done;`
sql_on=`echo ${sql_on}|sed 's/ / and /g'`

# 抽取主键完毕进行sql比对，将差异主键存储到文件
sql="select ${ydzj_col} from
(select ${sql_col} from ${tar_project}.${ntable} where rfq=${bizdate}) ydzj
left join 
(select ${sql_col} from sc_jc_gszj.${tar_tab} where rfq=${bizdate} and sjlybz='${dwmc}') odps
on ${sql_on}
where ${sql_where} ;"

echo "查询差异主键的sql是：${sql}"

pk1=`echo ${sql_col}|awk -F ',' '{print $1}'` # 截取第一个主键列用来去除行那一列，一个名称即可定位到
echo ${sql} >"${sql_dir}/${tar_project}${ntable}.sql"	# 存储对比sql
# 将查询结果除去结果之外的行获得的结果是'23317041910051157989|20123300100001208571' 写入文件，如果是一个列，那么直接就是'23317041910051157989'
${odpscmd} -e "${sql}"|grep -viE "\+-|${pk1}"|awk '{print $2}'|sed 's/ //g'|sed "s/^./'/g"|sed "s/.$/'/g"|grep -v '^$' >"${cypk_dir}/${tar_project}${ntable}.pk" 

#============================== 清理分割文件记录 ==============================
fgwj="${curdir}/${dwmc}_${bizdate}_splitpk.txt"
if [ -f "${fgwj}" ]; then rm -f ${curdir}/${dwmc}_${bizdate}_splitpk.txt; fi;	# 如果文件存在则删除
# 切割开超过in条件的
cys=`cat ${cypk_dir}/${tar_project}${ntable}.pk |wc -l`
if [ "${cys}" -le 0 ]; then echo "没有获取到差异！！！"; continue; fi;
if [ ${cys} -gt 10000 ]
then
echo "${tar_tab} 差异超过一万行，超过odps导出最大限制，请全量初始化"; >&1|tee -a ${err_dir}/check_table_err.txt
continue
fi;
if [ ${cys} -gt 800 ]   # 1000还是会超过长度，造成json读取不完全
then
row_start=1
file_num=1
echo ${tar_tab} >>"${curdir}/${dwmc}_${bizdate}_splitpk.txt"  # 存储起来
while [ ${row_start} -lt ${cys} ]
do
row_end=$((row_start+799))
sed -n "${row_start},${row_end}p" ${cypk_dir}/${tar_project}${ntable}.pk > ${cypk_dir}/${tar_project}${ntable}.pk+${file_num}
row_start=$((row_end+1))  # 条数从结束的下一条开始
file_num=$((file_num+1))
done

mv ${cypk_dir}/${tar_project}${ntable}.pk ${cypk_dir}/bak_${ntable}.pk  # 如果分割将原文件替换为备份文件，运行的时候就可以略过,切割完毕后再移动
fi;

# 将结果数据插回到N表，全部循环去处理,也可能1个，也可能多个，所以拼接和运行json的工作要放在这里面
select_sql=""
pk_num=`echo ${pk_col}|sed 's/"//g'|awk -F '|' '{print NF}'`  # 获取到主键个数

# 拼接where条件,每个文件，每个主键列的拼接
for filename in `ls ${cypk_dir} |grep "${tar_project}${ntable}.pk"`
do
swhere=""
# 如果多主键每个主键列的拼接
if [ ${pk_num} -gt 1 ]
then
for i in `seq 1 ${pk_num}`
do
pk_temp=`echo ${sql_col}|awk -F ',' "{print $"$i"}"`
tj_temp=`cat ${cypk_dir}/${filename} |awk -F '|' "{printf $"${i}","}|sed 's/.$//g'`
# 如果大于0则需要拼接and否则不需要
if [ ${#swhere} -gt 0 ];then swhere="${swhere} and ${pk_temp} in (${tj_temp})";fi;
done
elif [ ${pk_num} -eq 1 ]
then
# 因为1是大多数，所以如果是1就直接跳过上面的步骤提高效率
tj=$(cat ${cypk_dir}/${filename} |awk '{printf $0","}'|sed 's/.$//g')
swhere="${pk1} in (${tj})"
fi


# 获取基础层列
odps_col=$(${odpscmd} -e "desc ${tar_project}.${ntable};"|grep -E 'bigint|string|boolean|double|datetime|decimal' | awk '{print $2}' | awk '{printf $0","}'|sed 's/^/"/g'|sed 's/,/","/g'|tr 'a-z' 'A-Z')
odps_col=$(echo ${odps_col%"RFQ"*})  # 从右边开始第一个PARTITION右边的内容都删除掉，如果选择左边使用${odps_col#*PARTITION}  删除的包含指定的分割符
odps_col=$(echo ${odps_col}|sed 's/..$//g') # 替换最后两个字符 |sed 's/..$//g' 如果是替换最开始的两个应该是sed 's/^..//g'

echo "目标表列：${odps_col}"

# 中间碰到列目标表列和源表列顺序不一致的情况，我们判断之后处理一个顺序,后续加个判断
json_col=`echo ${odps_col} |sed 's/,"YPTETL_SJ"//g'`
# 处理时间类型列
date_col=`${odpscmd} -e "desc ${tar_project}.${ntable};"|grep 'datetime' | awk '{print $2}'|tr 'a-z' 'A-Z'`
for i in `echo ${date_col}` ;
do
# echo "当前正在处理的是${i}"
source_col=`echo ${json_col}|sed "s/${i}/case when ${i} <to_date('00010101','yyyymmdd') then to_date('00010101','yyyymmdd') when ${i} >to_date('99991231235959','yyyymmddhh24miss') then null else ${i} end/g"`
done

echo "源端表列：${source_col}"
# 处理目标日分区，如果没有切分则为bizdate 如果切分之后的为名称后面的 bizdate+序号 格式
xh=""
rfq="${bizdate}";
sffg=`echo ${filename}|grep '+' | wc -l`
if [ ${sffg} -ge 1 ]
then
xh=`echo ${filename}|awk -F '+' '{print "00"$2}'`;
rfq="${bizdate}${xh}";
fi;

# 存储获取结果
# echo "${source_tab}${source_col} odps column is ：${odps_col}" >${curdir}\all.config

################################################### 拼接抽取缺失全列数据JSON ###################################################
speed="10"
truncate="true"


json="{
\"job\": {
  \"content\":[
	{
	  \"reader\":{
		\"name\":\"${db}\",
		\"parameter\":{
		  \"column\":[${source_col},
			\"sysdate\"
		  ],
		  \"connection\":[
			{
			  \"jdbcUrl\":[
				\"jdbc:oracle:thin:@${jdbc}\"
			  ],
			  \"table\":[
				\"${owner}.${sourcetable}\"
			  ]
			}
		  ],
		  \"fetchSize\":1024,
		  \"password\":\"${pass}\",
		  \"splitPk\":${pk_col},
		  \"username\":\"${user}\",
		  \"where\":\"SJTB_SJ<to_date('${curdate}','yyyy-mm-dd') and ${swhere}\"
		}
	  },
	   \"writer\":{
		 \"name\":\"odpswriter\",
		 \"parameter\":{
		   \"accessId\":\"${odpsaccessId}\",
		   \"accessKey\":\"${odpsaccessKey}\",
		   \"column\":[${odps_col}
		   ],
		   \"odpsServer\":\"${odpsServer}\",
		   \"partition\":\"rfq=${rfq}\",
		   \"project\":\"${tar_project}\",
		   \"table\":\"${ntable}\",
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
	  \"channel\":${speed}
	}
  }
 }
}"
echo ${json} >&1|tee -a ${json_cydir}/${tar_tab}${xh}.json

# 这里也不能到后台取运行，否则会导致地下的未获取到内容，现在来看如果想要并发跑，还是分开最合理
nohup python /home/admin/datax3/bin/datax.py  --jvm="-Xms2g -Xmx8g"  ${json_cydir}/${tar_tab}${xh}.json  >${log_cydir}/${tar_tab}${xh}.log 2>&1

err=`cat ${log_cydir}/${tar_tab}${xh}.log|grep 'com.alibaba.datax.common.exception' |wc -l`
if [ ${err} -gt 0 ]; then echo "根据差异主键执行抽取数据json失败！！！"; cat ${log_cydir}/${tar_tab}${xh}.log|grep 'com.alibaba.datax.common.exception'; continue; fi;


# 将要合并的分区查询sql准备好,是不是分区表的在外层在判断
sqllength=`expr length "${select_sql}"`

if [ "${sqllength}" -lt 10 ]; then
select_sql="select ${odps_col} from ${tar_project}.${ntable} where rfq='${rfq}'";
else
select_sql="${select_sql} union all select ${odps_col} from ${tar_project}.${ntable} where rfq='${rfq}'";
fi;

select_sql=`echo ${select_sql}|sed 's/"//g'`

# echo "sql的长度是：${sqllength}"
# echo "sql是：${select_sql}"
done;


# ========================= 按照分割名单拼接sql处理分区到当前分区 =========================
if [ -f "${fgwj}" ]; then
temp_sl=`cat ${curdir}/${dwmc}_${bizdate}_splitpk.txt |grep -iw ${tar_tab} |wc -l`;  # 忽略大小写全字匹配
if [ "${temp_sl}" -gt 0 ]; then 
insert_sql="insert overwrite table ${tar_project}.${ntable} partition (rfq='${bizdate}')
${select_sql};";
echo "合并分区的sql是：${insert_sql}";
${odpscmd} -e "${insert_sql}"; fi;
fi;


# ========================= 再次关联后进行插入，确保插入的是真实没有的 =========================
odps_col=`echo ${odps_col}|sed 's/"//g'|tr [a-z] [A-Z]`
# select_col=`${odpscmd} -e "desc sc_jc_gszj.${tar_tab};"|grep -v 'rfq'|grep -v 'rfq'|grep -E 'bigint|string|boolean|double|datetime|decimal' | awk '{print "cy."$2" as "$2}'| awk '{printf $0","}'| tr '[a-z]' '[A-Z]'|sed 's/.$//g'`; 
targetCols=`${odpscmd} -e "desc sc_jc_gszj.${tar_tab};"|grep -viE 'rfq|SJLYBZ|SJLYBZ_JZ'|grep -E 'bigint|string|boolean|double|datetime|decimal' | awk '{print $2}'|tr [a-z] [A-Z]`


#比较临时层和基础层的表结构，基础层多的列用null补全
sourceCols=`echo ${odps_col}|sed 's/,/ /g'`
select_col=$(
num=1
for tarCol in ${targetCols}
do
temp="NULL"
    for souCol in ${sourceCols}
    do
       if [ "${tarCol}" == "${souCol}" ]
       then
           temp="cy.${souCol}"
           break
       fi 
       if [[ "${tarCol}" == "SJLYBZ_JZ" && "${souCol}" == "SJLYBZ" ]]
       then
       temp="cy.SJLYBZ"
       fi
    done
    if [ ${num} -eq 1 ]
    then
       str1="${temp} as ${tarCol}"
       num=2
    else
       str1="${str1},${temp} as ${tarCol}"
    fi
done
echo ${str1})

finish_sql="insert into sc_jc_gszj.${tar_tab} partition (rfq='${bizdate}',sjlybz='${dwmc}')
select ${select_col} from (select ${odps_col} from ${tar_project}.${ntable} where rfq='${bizdate}') cy
left join (select ${pk1} from sc_jc_gszj.${tar_tab} where rfq='${bizdate}' and sjlybz='${dwmc}') ly on cy.${pk1}=ly.${pk1} where ly.${pk1} is null"

echo "插入基础层的脚本是：${finish_sql}" # 打印出来看下即可，这一块应该没有太大变化

# ${odpscmd} -e "${finish_sql};";  测试期间先注销

# ================================= 循环结束 =================================
echo >&3	# 执行完毕将令牌放回管道
}&			# 放到后台开启下一个
done;

wait

exec 3<&-	# 关闭文件描述符读
exec 3>&-	# 关闭文件描述符写

exit 0