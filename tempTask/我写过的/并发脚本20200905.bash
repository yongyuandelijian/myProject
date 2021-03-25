#! /bin/bash
# 测试并发
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

# 拿出令牌，进行并发操作
for line in $(seq 1 50)
do
read -u3	# 读取一行获取一个令牌
{
echo ${line}
echo >&3	# 执行完毕将令牌放回管道
}
done
wait

exec 3<&-	# 关闭文件描述符读
exec 3>&-	# 关闭文件描述符写