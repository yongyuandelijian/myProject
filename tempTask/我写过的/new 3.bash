#!/bin/bash
curdir='/home/zr_user/WX/hx_sb_sb_sbxx'
curhour=`date +%H`

cd "${curdir}"
# 创建文件描述符 
if [ -f ${curdir}/tempfifo ]; then rm -f ${curdir}/tempfifo; fi;
mkfifo ${curdir}/tempfifo
exec 3<>${curdir}/tempfifo
rm -f ${curdir}/tempfifo

# 每次创建令牌2个
for i in `seq 1 2`;
do
echo >&3
done;

# 开启并发每次运行两个,夜间不在启动新的
for dwmc in `cat dwmc.list`;
do
read -u3
{
if [ ${curhour} -ge 7 ];then
python /home/zr_user/datax3/bin/datax.py --jvm="-Xms2g -Xmx8g" ${curdir}/${dwmc}/hx_sb_sb_sbxx.json > ${curdir}/${dwmc}/hx_sb_sb_sbxx.log 2>&1;
# 如果其中有单位开始报错，说明数据量已经过大，所以程序退出
err_num=`cat ${curdir}/${dwmc}/hx_sb_sb_sbxx.log|grep 'com.alibaba.datax.common.exception' |wc -l`
if [ ${err_num} -gt 0 ]; then echo "执行json失败！！！"; exit -1; fi;
echo >&3
fi;
} &

done;

wait

exec 3<&-
exec 3>&-

exit 0