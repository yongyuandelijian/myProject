#sc_sjzlpt（v3）配置                                                           #
################################################################################
dbanme=2222                                                               #
hostname=127.0.0.1                                                          #
username=111                                                          #
password=222                                                      #
port=3306                                                                      #
################################################################################ 

mysql -h${hostname} -P${port} -u${username} -p${password} -D ${dbanme} -N -e "${dbsql}"

--datasource_conf
INSERT INTO `datasource_conf`(`dwmc`, `sysname`, `db`, `jdbc`, `user`, `pass`, `createtime`, `updatetime`) VALUES ('AHLT', 'HXZG', 'oraclereader', '99.12.100.241:1521/ahlthxff', 'hx_odps', 'odps123',NULL,NULL);
INSERT INTO `datasource_conf`(`dwmc`, `sysname`, `db`, `jdbc`, `user`, `pass`, `createtime`, `updatetime`) VALUES ('AHST', 'HXZG', 'oraclereader', '99.12.100.205:1521/ahsthxff', 'hx_odps', 'odps123',NULL,NULL);

--column_conf
replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,clumns,swhere,createtime,updatetime) values ('AHLT','SC_JX_JSLT','LS_HX_PZ_PZ_FLZ','HX_PZ','PZ_FLZ','JZXHUUID,XHUUID,JZPZBH,PZDW_DM,TFRQ,YSPZHM,YSPZMXHM,YSPZBH_1,PZ_YSPZ_DM,TZLX_DM,PZZL_DM,PZZG_DM,PZZY_DM,PZQSHM,PZZZHM,RKS,FCS,KJS,ZFS,SSHXS,TYZFS,BJ_JC,SS_JC,ZL_BJ_JC,ZL_SS_JC,ZFBZ_1,LRR_DM,LRRQ,XGR_DM,XGRQ,SJGSDQ,SJTB_SJ','(sjtb_sj>=to_date('bizdate','yyyymmdd'))and(sjtb_sj<to_date('bizdate','yyyymmdd')+1)',now(),now())

--count_conf
insert into `count_conf` (`project`,`odps_tablename`,`createtime`,`updatetime`) values ('SC_JX_JSLT','HX_PZ_PZ_FLZ',now(),now());

pssh -ih /root/.pd/list/base.gatewaync  "docker exec \$(docker ps |grep BaseBizGateway|awk '{print \$1}') bash -c \"  /bin/sh '/home/admin/tar_pd.sh' version \""^C


#cat column.conf |awk -F "|" '{print substr($1,7,4)}'
#cat column.conf |awk -F "|" '{print $7}'
#
#cat column.conf |awk -F "|" '{print "'\''"$1"""'\''""'\''"$2"""'\''""'\''"$3"""'\''""'\''"$4"""'\''""'\''"$5"""'\''""'\''"$6"""'\''""'\''"$7"""'\''"}'
#
#cat column.conf |awk -F "|" '{print "'\''"$1"'\'',""'\''"$2"'\'',""'\''"$3"'\'',""'\''"$4"'\'',""'\''"$5"'\'',""'\''"$6"'\'',""'\''"$7"'\'',"}'
cat column.conf |awk -F "|" '{print "'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$5"""'\'',""'\''"$6"""'\'',""'\''"$7"""'\'',"}'

#拼接replace into sql
#cat column.conf |awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''"substr($1,7,4)"""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""'\''"$7"""'\'',""now()"",""now());"}'
#
#
#mysql -h${hostname} -P${port} -u${username} -p${password} -D ${dbanme} -f "/home/zr_user/yinqiang/column_to_rds/AHLT.sql"
#
#cat column.conf |awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''"substr($1,7,4)"""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',"$7"',""now()"",""now());"}'|grep bizdate
#
#
#
#cat column.conf |awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''"substr($1,7,4)"""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""'\''"$7"""'\'',""now()"",""now());"}'|grep bizdate


cat column.conf |awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''"substr($1,7,4)"""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'
mysql -h${hostname} -P${port} -u${username} -p${password} -D ${dbanme} < AHLT.sql 

cat column.conf |awk -F "|" '{print "\""$7"\""}'  




cat column.conf |awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''"substr($1,7,4)"""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}' >/home/zr_user/yinqiang/column_to_rds/AHLT.sql

--批量生成replace into语句
for i in `ls |grep 'T$'|grep -v 'GSZJ_TEST'`;do echo ${i};
cat /home/zr_user/version/${i}/column.conf|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''"substr($1,7,4)"""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}' >/home/zr_user/yinqiang/column_to_rds_70/${i}.sql;
done

--批量写入rds
for i in `ls `
do
echo ${i}
mysql -h${hostname} -P${port} -u${username} -p${password} -D ${dbanme} < ${i}
done

 
awk 'NR>10 && NR<15 {print}' datasource.conf |awk -F '=' '{print $2}'|tr '\n' '||' |awk -F '|' '{$1","$2,"$3"}'

awk 'NR>10 && NR<15 {print}' datasource.conf |awk -F '=' '{print $2}'|tr '\n' '||' |awk -F '|' '{print $2"|" "\"""HXZG""\"" "|" $1"|"$2"|"$3"|"$4"|""now(),now()"}'|sed 's/|/,/g'


awk 'NR>10 && NR<15 {print}' datasource.conf |awk -F '=' '{print $2}'|tr '\n' '||' |awk -F '|' '{print "\""toupper(substr($2,21,4))"\"" "|" }'
"AHLT"|


awk 'NR>10 && NR<15 {print}' datasource.conf |awk -F '=' '{print $2}'|tr '\n' '||' |awk -F '|' '{print "\""toupper(substr($2,21,4))"\"""|" "\"""HXZG""\"" "|" $1"|"$2"|"$3"|"$4"|""now(),now()"}'|sed 's/|/,/g'
"AHLT","HXZG","oraclereader","99.12.100.241:1521/ahlthxff","hx_odps","odps123",now(),now()

awk 'NR>10 && NR<15 {print}' datasource.conf |awk -F '=' '{print $2}'|tr '\n' '||' |awk -F '|' '{print "replace into datasource_conf (dwmc,sysname,db,jdbc,user,pass,createtime,modifytime) values (" "|" "\""toupper(substr($2,21,4))"\"""|" "\""toupper(substr($2,25,4))"\"" "|" $1"|"$2"|"$3"|"$4"|""now(),now());"}'|sed 's/|/,/g'


awk 'NR>10 && NR<15 {print}' datasource.conf |awk -F '=' '{print $2}'|tr '\n' '||' |awk -F '|' '{print "replace into datasource_conf (dwmc,sysname,db,jdbc,user,pass,createtime,modifytime) values (" "\""toupper(substr($2,21,4))"\"""|" "\""toupper(substr($2,25,4))"\"" "|" $1"|"$2"|"$3"|"$4"|""now(),now());"}'|sed 's/|/,/g'
replace into datasource_conf (dwmc,sysname,db,jdbc,user,pass,createtime,modifytime) values ("AHLT","HXFF","oraclereader","99.12.100.241:1521/ahlthxff","hx_odps","odps123",now(),now());

--批量处理count.conf文件
for i in `ls |grep 'T$'|grep -v 'GSZJ_TEST'`;do echo ${i}; ii=`echo ${i}|sed 's/^/SC_JX_/g'`;echo $ii
cat /home/zr_user/version/${i}/count.conf |sed "s/^/$i|$ii|/g"|awk -F '|' '{print "replace into count_conf (dwmc,project,odps_tablename,createtime,updatetime) values (" "\""$1"\""",""\""$2"\""",""\""$3"\""",""now(),now());"}' >/home/zr_user/yinqiang/count_to_rds/${i}.sql;
done
--批量写入rds
for i in `ls `
do
echo ${i}
mysql -h${hostname} -P${port} -u${username} -p${password} -D ${dbanme} < ${i}
done


--------------特殊处理的column----------------
1 HLW （原表缺少owner，因此用表名称补齐）
cat column.conf |awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''HLW""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""\""$5"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/HLW.sql
mysql -h${hostname} -P${port} -u${username} -p${password} -D ${dbanme} < HLW.sql

2 WHTS
cat column.conf |awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''WHTS""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/WHTS.sql

3 WHSJ
cat column.conf |awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''WHSJ""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/WHSJ.sql

4 WBJH_BG
cat column.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''WBJH_BG""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/WBJH_BG.sql

5 WBJH
cat column.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''WBJH""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/WBJH.sql

6 JC_GSZJ
cat column.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''JC_GSZJ""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/JC_GSZJ.sql

7 FXQB
cat column.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''FXQB""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/FXQB.sql

8 DZSW
cat column.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''DZSW""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/DZSW.sql

9 CKTS
cat column.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''CKTS""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/CKTS.sql

10 GSZJ
cat column.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''GSZJ""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/GSZJ.sql

cat column_ckts.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''GSZJ""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/GSZJ_CKTS.sql

cat column_yshd.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''GSZJ""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/GSZJ_YSHD.sql

cat count.conf |sed "s/^/GSZJ|SC_JX_GSZJ|/g"|awk -F '|' '{print "replace into count_conf (dwmc,project,odps_tablename,createtime,updatetime) values (" "\""$1"\""",""\""$2"\""",""\""$3"\""",""now(),now());"}' >/home/zr_user/yinqiang/count_to_rds/GSZJ.sql;

11 GSZJ_TEST
cat column.conf |grep -v '^$'|awk -F "|" '{print "replace into column_conf (dwmc,project,odps_tablename,oracle_owner,oracle_tablename,columns,swhere,createtime,updatetime) values (""'\''GSZJ_TEST""'\'',""'\''"$1"""'\'',""'\''"$2"""'\'',""'\''"$3"""'\'',""'\''"$4"""'\'',""'\''"$6"""'\'',""\""$7"\""",""now()"",""now());"}'>/home/zr_user/yinqiang/column_to_rds/GSZJ_TEST.sql


information_schema.columns|sjzl_meta_rds_columns|`table_catalog`,`table_schema`,`table_name`,`column_name`,`ordinal_position`,`column_default`,`is_nullable`,`data_type`,`character_maximum_length`,`character_octet_length`,`numeric_precision`,`numeric_scale`,`datetime_precision`,`character_set_name`,`collation_name`,`column_type`,`column_key`,`extra`,`privileges`,`column_comment`|`table_schema`
information_schema.schemata|sjzl_meta_rds_schemata|catalog_name,schema_name,default_character_set_name,default_collation_name,sql_path|`schema_name`
information_schema.tables|sjzl_meta_rds_tables|`table_catalog`,`table_schema`,`table_name`,`table_type`,`engine`,`version`,`row_format`,`table_rows`,`avg_row_length`,`data_length`,`max_data_length`,`index_length`,`data_free`,`auto_increment`,`create_time`,`update_time`,`check_time`,`table_collation`,`checksum`,`create_options`,`table_comment`|`table_schema`

