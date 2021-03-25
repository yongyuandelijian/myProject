#!/bin/bash
bizdate="$1"
formatdate="${bizdate:0:4}-${bizdate:4:2}-${bizdate:6:2}"
lastdate=`date -d "${formatdate}" +%s`
lastdate01=$[lastdate-86400*1]
echo ${lastdate01}
lastdate01=`date -d @${lastdate01} +%Y%m%d `
echo ${lastdate01}
#70个单位的列表
dwlist='AHLT AHST BJLT BJST CQLT CQST DLLT DLST FJLT FJST GDLT GDST GSLT GSST GXLT GXST GZLT GZST HALT HAST HBLT HBST HELT HEST HILT HIST HLLT HLST HNLT HNST JLLT JLST JSLT JSST JXLT JXST LNLT LNST NBLT NBST NMLT NMST NXLT NXST QDLT QDST QHLT QHST SCLT SCST SDLT SDST SHST SNLT SNST SXLT SXST SZLT SZST TJLT TJST XJLT XJST XMLT XMST XZST YNLT YNST ZJLT ZJST'
#获取${lastdate01}当天数据的sjlybz列表
ddlsql='select sjlybz from hx_dj_dj_nsrxx where rfq = '${lastdate01}' group by sjlybz order by sjlybz limit 100;'
resultlist=`/home/admin/odpscmd/bin/odpscmd --project=sc_jc_gszj -e "${ddlsql}"|grep -v "+-"|grep -v "^| sjlybz "|sed 's/|//g'|sed 's/ //g'`
#获取列表比对结果
result1=$(
for i in ${dwlist}
do 
  for j in ${resultlist}
  do
    temp="null"  
    if [ "${i}" == "${j}" ]
	then 
	  break
	else
	  temp="${i}"
	fi
  done
  echo ${temp}
done)
result=`echo ${result1}|sed 's/ null//g'|sed 's/null //g'|sed 's/null//g'|sed 's/ /,/g'`
if [[ ! -n ${result} ]];then echo "${lastdate01}当天，70个单位数据齐全"; exit 0;fi;
#将延时的单位写入xnjc_to_success_info表中
insql="insert overwrite table xnjc_to_success_info partition (rfq = '${lastdate01}') select '${result}' from sc_jc_gszj.dual;"
echo ${insql}
/home/admin/odpscmd/bin/odpscmd --project=sc_jc_gszj -e "${insql}";
echo "task run over "

