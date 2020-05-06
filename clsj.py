#!/usr/bin/env python
# -*- coding: utf-8 -*-

__author__ = "aaa"
__time__ = "2020-04-16"

import os
import pymysql
SQL_FILE_PATH=r'E:\work\sjcl20200416\dclsj0416\mx_ksqy_nsrxx_mx'
fh=r"\a"
PATH=os.path.dirname(os.path.abspath(SQL_FILE_PATH))+fh[0:1]  # 为了拼接特殊符号\
ERROR_TABLENAME = set()  # 存储出错的表名称，因为存在数据和结构不匹配的情况
# 找出所有的sql文件名称
def get_sql_files():
    sql_files = []
    # files = os.listdir(os.path.dirname(os.path.abspath(__file__)))
    files = os.listdir(PATH)
    print(len(files))
    for file in files:
        if os.path.splitext(file)[1] == '.sql':
            sql_files.append(file)
    return sql_files

# 获取数据库连接执行sql
def connectMySQL():
    # 打开数据库连接
    db = pymysql.connect(host="127.0.0.1", user="root", port=3306, password="Abcd_1234", charset='utf8mb4',database='test')

    # 使用 cursor() 方法创建一个游标对象 cursor
    cursor = db.cursor()

    for file in get_sql_files():
        # print("路径是：",os.path.dirname(SQL_FILE_PATH))
        # print("现在处理的文件是：",file)
        executeScriptsFromFile(file, cursor)
    db.commit()  # 必须手动提交，否则回造成没有问题，但是也没有数据
    db.close()


# 读取单个sql文件并执行脚本
def executeScriptsFromFile(filename, cursor):
    filename=PATH+filename
    print("现在处理的文件是：", filename)
    fd = open(filename, 'r', encoding='utf-8')
    sqlFile = fd.read()
    fd.close()
    sqlCommands = sqlFile.split(';')  # 获取到一个文件语句的列表
    for command in sqlCommands:
        command.replace(r"\n", "")
        try:
            if "INSERT" in command:  # 如果是插入语句则执行，否则舍弃
                print("现在要执行的语句是：", command)
                cursor.execute(command)
        except Exception as msg:
            print(msg)
            ERROR_TABLENAME.add(filename)
            break




if __name__ == "__main__":
    connectMySQL()
    print('sql执行完成,错误的个数是{gs}表名单是：{md}'.format(gs=len(ERROR_TABLENAME),md=ERROR_TABLENAME))
