# 功能：提供操作数据库的方法
# date:20200723
# author:aaa
import pymysql
import getsqlconfig

class getsqldata(object):

    def getdata(self,sql):
        '''功能：根据传入的sql获取到数据，然后将数据返回'''
        # path = r"E:\work\config\sqlconfig.ini" 这里面用不了，取消
        # host,port,schema,user,password,charset=getsqlconfig.get_sqlconfig(path)
        # 打开数据库连接
        db = pymysql.connect(host="99.13.220.242", user="rcount", passwd="rcount", db="rcount")

        # 使用 cursor() 方法创建一个游标对象 cursor
        cursor = db.cursor()

        # 使用 execute()  方法执行 SQL 查询
        cursor.execute(sql)

        # 使用 fetchone() 方法获取单条数据.
        # data = cursor.fetchone()

        data=cursor.fetchall()
        # for row in data:
        #     rq=row[0]
        #     jcs=row[1]
        #     ycdw=row[2]

        # 关闭数据库连接
        db.close()
        return data