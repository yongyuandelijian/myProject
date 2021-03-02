from docx import Document
from sqlcommand.getsqldata import getsqldata
import re

# 功能： 将word表格中获取到的表和列注释和excel的内容逐项比对，将对应的表列注释更新
# word中给出的列表每个元素是一列内容，样式['ADP', 'WBJH_ZJFWZX_HGZDZCX', '中机中心合格证电子撤销', 'SFCQ', '是否抽取过：Y 表示是，N表示否', 'VARCHAR2(2)', '否']
# 需要用到的列：下标分别是 1  表名称 2 表注释  3 列名称 4 列注释
#  excel 第6列 f 表名称  第7列 g 表注释  第8列 h 列名称  第9列 i 列列注释
# 如果表名称相同，则将表注释写入，如果表名称相同并且列名称相等，则将列注释写入，写入后continue 跳出当前比对，进行下一次比对
# aaa 20210202

word_path=r"..\appendix\外部信息交换系统数据字典.docx"
excel_path=r"..\appendix\t_sjzd_comnull.xlsx"

def writeFile(text):
    with open('result.txt','a') as fileobj:
        # fileobj.write(text)
        fileobj.writelines(text+"\n")
        fileobj.close()

def getworktable():
    """从word中将多个表按照结构获取到表和列的注释"""
    doc = Document(word_path)
    tables = doc.tables

    # 获取表格
    tc = 0
    temp_bxx = []  # 用来存放表信息
    table_comment=[]
    col_comment=[]
    for table in tables:
        tc += 1
        # print("================== 第{tc}个表 =======================".format(tc=tc))
        if tc > 2 and tc % 2 == 1:
            temp_bxx = []
        if tc % 2 == 1:
            cc = 0
            # 将一个表的信息全部存储进来
            for col in table.columns:
                cc += 1
                # print("================== 第{cc}列 =======================".format(cc=cc))
                if cc == 2:
                    for cell in col.cells:
                        text = cell.text.replace('\n', '')
                        # if len(text)>0:  不判断，插入空在对比时校验
                        temp_bxx.append(text)
            table_comment.append(temp_bxx)

        elif tc % 2 == 0:
            rc = 0
            for row in table.rows:
                rc += 1
                # print("================== 第{rc}行 =======================".format(rc=rc))
                temp_lxx = []  # 用来存放列基本信息
                for xx in temp_bxx:
                    temp_lxx.append(xx)
                for cell in row.cells:
                    if rc != 1:
                        text = cell.text.replace('\n', '')
                        # if len(text)>0: 不需要判断
                        temp_lxx.append(text)
                # print(temp_lxx)

                if len(temp_lxx) > len(temp_bxx):
                    col_comment.append(temp_lxx)
    # print(col_comment)   # 有内容的5095个列
    return col_comment

def excuteSql(sql):
    zxsql=getsqldata()
    print(sql)
    zxsql.zxsql(sql)



if __name__ == '__main__':
    col_comment=getworktable()
    for temprow in col_comment:
        sql="insert into aaa_test_word0203 values('{yh}','{bmc}','{bzs}','{lmc}','{lzs}');".format(yh=temprow[0],bmc=temprow[1],bzs=temprow[2],lmc=temprow[3],lzs=temprow[4])
        # print(sql)
        # writeFile(sql)
        excuteSql(sql)


