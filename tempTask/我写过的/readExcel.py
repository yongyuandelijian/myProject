# 读取Excel内容拼接备注语句
# alter table table_name change column column_name  comment '列注释'
# alter table sc_jc_gszj.cx_ypt_sjcc_wbjh_hg_bgd set comment '海关报关单';
import os
import xlrd

path=r'C:\Users\zr20191007\Desktop\document'
resultfile="result_sql.txt"

# 如果存在结果txt先进行删除
result_path=os.path.join(path,resultfile)

def writefile(txt):
    '''将传入文本写入文档'''
    f=open(resultfile,'a')  # 若文件不存在则创建文件，然后追加写入
    f.write(txt)
    f.write("\n")
    f.close()

if os.path.exists(result_path):
    os.remove(result_path)

files=os.listdir(path)
for file in files:
    if file.split('.')[1]=="xls" or file.split('.')[1]=="xlsx":
        full_filepath=os.path.join(path,file)
        print("获取到Excel文件,",full_filepath)
        workbook=xlrd.open_workbook(full_filepath)
        sheets=workbook.sheet_names()
        for sheet in sheets:
            sheet_dx = workbook.sheet_by_name(sheet)
            # 如果是表名就是表名单，拼接增加表注释，如果是其他就是增加列注释,分别写入各自的文件
            if sheet=="数据字典":
                row_num=sheet_dx.nrows
                col_num=sheet_dx.ncols
                for rowx in range(row_num):
                    row_list=[]
                    if rowx == 0:
                        continue
                    for colx in range(col_num):
                        if colx in (1,2):
                        # print("行号列号分别是：{rowx}{colx}".format(rowx=rowx,colx=colx))
                            temp_nr=sheet_dx.cell_value(rowx,colx)
                            row_list.append(temp_nr)
                    print(row_list)
                    comment_sql = r"alter table fxfxpt.{table_name} set comment '{comment}'".format(table_name=row_list[0], comment=row_list[1]);
                    writefile(comment_sql)
                    print(comment_sql)
            else:
                row_num = sheet_dx.nrows
                col_num = sheet_dx.ncols
                for rowx in range(row_num):
                    row_list = []
                    if rowx == 0:
                        continue
                    for colx in range(col_num):
                        if colx == 1:
                            continue
                        # print("行号列号分别是：{rowx}{colx}".format(rowx=rowx,colx=colx))
                        temp_nr = sheet_dx.cell_value(rowx, colx)
                        row_list.append(temp_nr)
                    # print(row_list)
                    comment_sql = r"alter table fxfxpt.{table_name} change column {column_name}  comment '{col_comment}';".format(table_name=sheet,column_name=row_list[0],col_comment=row_list[1])
                    writefile(comment_sql)
                    print(comment_sql)

