# encoding:utf-8
"""
功能：读取文件夹下的pdf内容，将发票直接读取到txt或者Excel中
author:aaa
date:20200906
注意内容：
1.python3不同与2版本不能使用pdfminer
2 python -m pip install pdfminer3k

"""
from pdfminer.converter import PDFPageAggregator
from pdfminer.layout import LAParams, LTTextBoxHorizontal
from pdfminer.pdfinterp import PDFTextExtractionNotAllowed, PDFResourceManager, PDFPageInterpreter
from pdfminer.pdfparser import PDFDocument, PDFParser
# from pdfminer.pdffont import PDFCIDFont


import os
import sys
import xlsxwriter

def wirteexcel():
    '''将传入的列表按照每一行的记录填写到Excel'''
    pass
def readpdf(fullpath):
    '''读取单个pdf内容'''
    fp_list=[]              # 定义一个列表来存储单个发票的内容
    fp=open(fullpath,"rb")  # 以二进制形式打开
    parser=PDFParser(fp)    # 创建一个解析器
    doc=PDFDocument()       # 创建一个文档
    # 相互绑定链接解析器和文档对象
    parser.set_document(doc)
    doc.set_parser(parser)
    doc.initialize()        # 如果有密码需要传入初始化密码

    # 如果文档可以txt转换就操作，否则就提示错误
    if doc.is_extractable:
        pdfrm=PDFResourceManager()  # 创建pdf资源管理器来管理公共资源，比如图片，字体一类的内容
        device=PDFPageAggregator(rsrcmgr=pdfrm,laparams=LAParams())  # 创建一个页面聚合器传入资源管理器和布局对象参数
        interpreter=PDFPageInterpreter(rsrcmgr=pdfrm,device=device)    # 创建一个页面解释器传入资源管理器和驱动

        # cidfont = PDFCIDFont(pdfrm,spec="simsun")
        # cidfont.cidcoding="simsun"
        # 处理每一个页面的内容
        for page in doc.get_pages():
            interpreter.process_page(page)  # 开启一个解析页面的进程
            layout=device.get_result()      # 获取该页面的布局对象
            for row in layout:
                # 如果是一个布局的水平布局的对象或者其子类，就开始获取内容
                if isinstance(row,LTTextBoxHorizontal):
                    results = row.get_text()
                    results=results.replace("\n","").replace(" ","")
                    fp_list.append(results)
                    # with open(r"E:\1.txt",'a') as tarfile:
                    #     results=row.get_text()
                    #     print("="*30)
                    #     print(results)
                    #     tarfile.write(results+"\n")
    else:
        raise PDFTextExtractionNotAllowed

    print(fp_list,len(fp_list))
    # print("="*50)
    # 发票代码	发票号码	税前金额	税率	价税合计	开票单位（销货方）	开票内容	开票时间	报销部门	报销人	备注
    # result_dict={
    #     "发票代码":fp_list[10],
    #     "发票号码":fp_list[11],
    #     "税前金额":fp_list[47],
    #     "税率":fp_list[46],
    #     "价税合计":fp_list[47],
    #     "开票单位（销货方）":fp_list[49],
    #     "开票内容":fp_list[23],
    #     "开票时间":fp_list[12],
    #     "报销部门":"大数据中心",
    #     "报销人":"",
    #     "备注":fp_list[55]
    # }
    # print(result_dict)


def runread(path):
    '''寻找目录发票文件'''
    if not os.path.exists(path):
        print("目录不存在，请检查！！！")
        sys.exit(-1)

    # 目录存在寻找pdf文件
    files=os.listdir(path)
    for filename in files:
        fullpath=os.path.join(path,filename)
        if os.path.isfile(fullpath):
            print("=========================<<{fullpath}>>=========================".format(fullpath=fullpath))
            readpdf(fullpath)

if __name__ == '__main__':
    path = r"E:\jichengzu\报销\发票"  # 指定目录
    runread(path)