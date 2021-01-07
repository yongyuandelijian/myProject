# 用于读取到数据库配置文件的相关配置,配置解析器
import configparser

def get_sqlconfig(filename):
    cf=configparser.ConfigParser() # 获取一个读取对象
    cf.read(filenames=filename,encoding='utf8') #读取配置文件
    # 读取对应的文件参数
    host=cf.get('mysql','host')
    port=cf.get('mysql','port')
    schema=cf.get('mysql','schema')
    user=cf.get('mysql','user')
    password=cf.get('mysql','password')
    charset=cf.get('mysql','charset')
    # sqlconfig=(host,port,schema,user,password,charset)   # 返回这个根本不好获取
    return host,port,schema,user,password,charset

# path=r"E:\work\config\sqlconfig.ini"
# mysql=get_sqlconfig(path)
# print(mysql)