# 功能：提供操作数据库的方法
# date:20200723
# author:aaa
import pymysql


class getsqldata(object):

    def getdata(self, sql):
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

        data = cursor.fetchall()
        # for row in data:
        #     rq=row[0]
        #     jcs=row[1]
        #     ycdw=row[2]
        # db.commit()  # 除了查询语句其他的看自己需求是否要提交
        # 关闭数据库连接
        db.close()
        return data

    def getzlzData(self, sql):
        '''功能：查询治理组的数据库'''
        db = pymysql.connect(host="99.15.2.214", user="cs_dsjsjzlpt", passwd="Css_sjzl_0616", db="cs_sjzlpt")
        cursor = db.cursor()
        cursor.execute(sql)
        data = cursor.fetchall()
        db.close()
        # 为了解决部分int数据被处理成float所以单独处理下，如果有更好的方式，可以去除这里
        data_list=[]
        # print(data)
        if data and type(data)==tuple:
            for r in data:
                temp_list = []
                if r and type(r)==tuple:
                    for c in r:
                        if type(c) == float:
                            c = int(c)
                        temp_list.append(c)
                data_list.append(temp_list)
        return data_list

    def getMetaData(self, sql):
        '''功能：查询元仓的数据库'''
        db = pymysql.connect(host="99.13.222.50", user="systemdata", passwd="systemdata_0705", db="systemdata")
        cursor = db.cursor()
        cursor.execute(sql)
        data = cursor.fetchall()
        db.close()
        return data