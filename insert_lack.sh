#!/bin/bash
###############################备注说明###############################
# 功能：差异补充缺失部分的数据
# 实现思路：1 从分发库获取指定单位表的全量主键到N表  
#			2 N表和基础层现有最新分区比较获取缺失的主键， 
#			3 根据缺失的主键从分发库查询到缺失的数据插回到N表 
#			4 再使用N表和基础层现有最新分区关联插入现在没有的部分，再次保证只插入缺失的部分
# author：aaa
# date: 20200810 第一版完成于20200818
# 参数：业务日期（20200810）  单位代码（SXST）  表单从[单位代码.list]中读取 (HX_FP_FP_DCXCQDB_MX)都是大表使用主键切分，暂时不使用并发
# 用法：nohup sh insert_lack.sh 20200831 SXST >insert_lack.log 2>&1 &

#####################################################################################################
# 参数准备
odpsServer=""     #
tunnelServer=""            #
odpsaccessId=""                                                #
odpsaccessKey=""   
# 传入参数
bizdate=$1
dwmc=$2
dwmc=`echo ${dwmc}|tr 'a-z' 'A-Z'`
tar_project="SC_JX_${dwmc}"
curdate=`date +"%Y-%m-%d"`

# 目录准备
curdir=`pwd`
json_dir="${curdir}/${dwmc}/${bizdate}/pk_json"  # 存储主键抽取json
log_dir="${curdir}/${dwmc}/${bizdate}/pk_log"	 # 存储主键抽取日志
json_cydir="${curdir}/${dwmc}/${bizdate}/json"   # 存储抽取差异全数据json
log_cydir="${curdir}/${dwmc}/${bizdate}/log"	 # 存储抽取全数据日志
sql_dir="${curdir}/${dwmc}/${bizdate}/sql"   	 # 存储主键对比的sql 方便后期排查问题
sql_dir="${curdir}/${dwmc}/${bizdate}/insertjc_sql" # 查询差异部分全部数据目录
cypk_dir="${curdir}/${dwmc}/${bizdate}/cypk"  	 # 存储差异的主键文本，包括总的和按照一千切分后的
err_dir="${curdir}/${dwmc}/${bizdate}/err"  	 # 存储错误日志
if [ ! -d ${json_dir} ]; then mkdir -p "${json_dir}"; fi;
if [ ! -d ${log_dir} ]; then mkdir -p "${log_dir}"; fi;
if [ ! -d ${sql_dir} ]; then mkdir -p "${sql_dir}"; fi;
if [ ! -d ${cypk_dir} ]; then mkdir -p "${cypk_dir}"; fi;
if [ ! -d ${json_cydir} ]; then mkdir -p "${json_cydir}"; fi;
if [ ! -d ${log_cydir} ]; then mkdir -p "${log_cydir}"; fi;
if [ ! -d ${err_dir} ]; then mkdir -p "${err_dir}"; fi;
if [ ! -d ${insertjc_sql} ]; then mkdir -p "${insertjc_sql}"; fi;
# 如果没有配置好直接退出
if [ ! -f "${dwmc}.list" ];then echo "${dwmc}.list is not exists,please check!!!"; exit -1; fi;

# 固定参数
odpscmd="/home/admin/odps/bin/odpscmd --endpoint= -u  -p  
--project=${tar_project}"
endpoint=''
accessid=''
accesskey=''

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
jdbc="-h127.0.0.1 -P3306 -uusername -ppassword -D schema"
sdata=`mysql $jdbc -N -e "${sql}"`
if [[ $? -ne 0 ]];then echo "rcount excute failed";exit -1;fi
echo $sdata
}


sql="select concat(db,'|',jdbc,'|',user,'|',pass) from fbk_datasource_conf where dwmc = '${dwmc}';"
echo ${sql}	
# echo `date "+%Y-%m-%d %H:%M:%S"`
mysqlcmd "rcount" "${sql}"
db=`echo ${sdata}  |awk -F "|" '{print $1}'`
jdbc=`echo ${sdata}|awk -F "|" '{print $2}'`
user=`echo ${sdata}|awk -F "|" '{print $3}'`
pass=`echo ${sdata}|awk -F "|" '{print $4}'`

# ================================ 检测下数据库延迟，如果副本库断开连接，则使用分发库进行连接,具体阀值暂时不能确定 ================================
# checksql="
# select to_char(sysdate,'yyyymmdd hh24:mi:ss')||'|',to_char(next_time,'yyyymmdd hh24:mi:ss')||'|',ceil((sysdate-next_time)*24*60) as yanshi  from v\$archived_log where applied = 'YES' and sequence#=(select max(sequence#) from v\$archived_log where applied = 'YES');"
# 
# select to_char(sysdate,'yyyymmdd hh24:mi:ss')||'|',to_char(next_time,'yyyymmdd hh24:mi:ss')||'|',ceil((sysdate-next_time)*24*60) as yanshi  from v$archived_log where applied = 'YES' and sequence#=(select max(sequence#) from v$archived_log where applied = 'YES');
# 
# ys=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
# set heading off
# set feedback off
# set pagesize 0
# set linesize 30000
# set verify off
# set echo off
# ${checksql}
# quit;
# END`
# echo ${dwmc}'|'${ys} >&1 |tee -a >>${mydir}/check_yanshi.log

# ================================ 按照表单准备数据 ================================
for tar_tab in `cat ${dwmc}.list`;
do
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
echo "${source_tab} get table info failed from source !!!" >&1 |tee -a ${err_dir}/check_table_err.txt  # 如果没有参数就是每次都是覆盖插入
continue
fi;


# 获取原表
sourcetable=`echo ${source_tab}|awk -F '|' '{print $3}'`
owner=`echo ${source_tab}|awk -F '|' '{print $2}'`


# 获取列名称 shell脚本前面放空格如果导致异常，所以尽量不要写一大段，这样不好识别
source_col=`sqlplus -S ${user}/\"${pass}\"@${jdbc} <<END
set heading off
set feedback off
set pagesize 0
set verify off
set echo off
select t.column_name from sys.dba_tab_columns t  where t.owner = upper('${owner}') and t.table_name=upper('${sourcetable}');
quit;
END`

# echo "表${source_tab}列${source_col}"
	
source_col=`echo ${source_col}|sed 's/^/"/g'|sed 's/ /","/g'|awk '{printf $0}'|tr '[a-z]' '[A-Z]'`
source_col="${source_col}\""

if [[ ! ${source_col} ]]
then
echo "${sourcetable} get columns info failed from source !!!" >&1|tee -a ${err_dir}/check_table_err.txt
continue
fi;

# 寻找主键
pk_col=`${odpscmd} -e "desc ${tar_project}.${ntable};" |grep 'primary_key'|awk '{print $2}'|tr 'a-z' 'A-Z'`

# 针对多个或者没有的单独处理，大多数都是1个
pk_count=`echo ${pk_col}|wc -l`
if [ ${pk_count} -gt 1 ]
then
# 暂时不在处理多个主键的情况列，因为多个主键拼接在一起，实际上还是不好校验，需要循环一个一个进来校验，如果后面需要处理多个主键的后续再从这里进行完善
pk_col=`echo ${pk_col}|awk '{printf $0","}'`
pk_col=`echo ${pk_col}|sed |sed 's/^/"/g'|sed 's/ /","/g'`
pk_col=${pk_col%?}
echo "多主键的部分暂时没有完善 ！！！";
exit -1;
elif [ ${pk_count} -eq 1 ]
then
pk_col=`echo ${pk_col}|sed 's/^/"/g'|sed 's/$/"/g'`
elif [ ${pk_count} -lt 1 ]
then
echo "${ntable} pk is not found";
exit -1;
fi;


echo "========================获取到的主键是:《${pk_col}》========================"
bd_result=`echo ${source_col} |grep ${pk_col}|wc -l`
if [ ${bd_result} -lt 1 ]
then
echo "原端列${source_col} 中不含主键 ${pk_col}，请检查！！！" >&1|tee -a ${err_dir}/check_table_err.txt
continue
else
echo "${tar_tab}源端和基础层表主键列比对通过。";
fi;
	
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
		  \"splitPk\":${pk_col},
		  \"username\":\"${user}\",
		  \"where\":\"SJTB_SJ<to_date('${curdate}','yyyy-mm-dd')\"
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

# 执行json可能会过多或者错误的json，所以这一行还是手动去操作吧,但是手动如果换下一个脚本还需要将上面的很多操作再次操作一遍
nohup python /home/admin/datax3/bin/datax.py  --jvm="-Xms2g -Xmx8g"  ${json_dir}/${tar_project}${ntable}.json  >&1 |tee -a ${log_dir}/${tar_project}${tar_tab}.log 2>&1
err=`cat ${log_dir}/${tar_project}${tar_tab}.log|grep 'com.alibaba.datax.common.exception' |wc -l`
if [ ${err} -gt 0 ]; then echo "执行抽取主键json失败！！！"; cat ${log_dir}/${tar_project}${tar_tab}.log|grep 'com.alibaba.datax.common.exception'; exit -1; fi;

# 处理需要的列
ydzj_col=`echo ${pk_col}|sed 's/"//g' |sed 's/^/ydzj./g' |sed 's/,/,ydzj./g'`
sql_col=`echo ${pk_col}|sed 's/"//g'`
sql_where=`echo ${pk_col}|sed 's/^/odps./g'`
sql_where="${sql_where} is null"
sql_where=`echo ${sql_where}|sed 's/"//g' |sed 's/,/ and odps./g'`
sql_on_left=`echo ${pk_col}|sed 's/^/ydzj./g'`
sql_on_right=`echo ${pk_col}|sed 's/^/odps./g'`
sql_on="${sql_on_left}=${sql_on_right}"
sql_on=`echo ${sql_on}|sed 's/,/ and /g'|sed 's/"//g'`
# 抽取主键完毕进行sql比对，将差异主键存储到文件
sql="select ${ydzj_col} from
(select ${sql_col} from ${tar_project}.${ntable} where rfq=${bizdate}) ydzj
left join 
(select ${sql_col} from sc_jc_gszj.${tar_tab} where rfq=${bizdate} and sjlybz='${dwmc}') odps
on ${sql_on}
where ${sql_where} ;"

echo ${sql}

pk=`echo ${pk_col}|awk -F ',' '{print $1}'|sed 's/"//g'`
echo ${sql} >"${sql_dir}/${tar_project}${ntable}.sql"
${odpscmd} -e "${sql}"|tr '[a-z]' '[A-Z]'|grep -vE "\+-|${pk}"|awk '{print $2}'|grep -v "^$"|sed 's/ //g'|sed "s/^/'/g"|sed "s/$/',/g" >"${cypk_dir}/${tar_project}${ntable}.pk"

#==============================清理分割文件记录-
fgwj="${curdir}/${dwmc}_${bizdate}_splitpk.txt"
if [ -f "${fgwj}" ]; then rm -f ${curdir}/${dwmc}_${bizdate}_splitpk.txt; fi;

# 切割开超过in条件的
cys=`cat ${cypk_dir}/${tar_project}${ntable}.pk |wc -l`
if [ "${cys}" -le 0 ]; then echo "没有获取到差异，清检查！！！"; continue; fi;
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
pk1=`echo ${pk_col}|sed 's/"//g'`
# 拼接where条件
for filename in `ls ${cypk_dir} |grep "${tar_project}${ntable}.pk"`
do
tj=`cat ${cypk_dir}/${filename} |awk '{printf $0}'`
tj=${tj%?}
swhere="${pk1} in (${tj})"

# 获取基础层列
odps_col=`${odpscmd} -e "desc ${tar_project}.${ntable};"|grep -v 'rfq'|grep -E 'bigint|string|boolean|double|datetime|decimal' | awk '{print $2}' | awk '{printf $0","}'| tr '[a-z]' '[A-Z]'|sed 's/^/"/g'|sed 's/,/","/g'|sed 's/..$//g'`; 

# /home/admin/odps/bin/odpscmd -e "desc SC_JX_SXST.N_HX_SB_SB_SDS_JMCZ_14ND_SEDMYHMXB;" |grep -v 'rfq'|grep -E 'bigint|string|boolean|double|datetime|decimal' | awk '{print $2}' | awk '{printf $0","}'| tr '[a-z]' '[A-Z]'|sed 's/^/"/g'|sed 's/,/","/g'|sed 's/..$//g'

# odps_col=${odps_col%?}
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

${odpscmd} -e "${finish_sql};";

# ================================= 循环结束 =================================
done;

exit 0