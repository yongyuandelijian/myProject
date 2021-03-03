import win32com
from win32com.client import Dispatch
import os
from docx import Document

def update_pagenum(wordPath):
    """更新word页码情况"""
    w = win32com.client.Dispatch("Word.Application")
    w.Visible = 0
    w.DisplayAlerts = 0

    doc = w.Documents.Open(wordPath)
    sumNum=w.ActiveDocument.ComputeStatistics(2)
    print(sumNum)

    doc.SaveAs(wordPath)
    doc.Close()


def wordtopdf(wordname):
    """将指定的word转为pdf"""
    word = Dispatch('Word.Application')
    doc = word.Documents.Open(wordname)
    doc.SaveAs(wordname.replace(".docx", ".pdf"), FileFormat="wdFormatPDF")  # 此方法必须安装word服务
    doc.Close()
    word.Quit()

# 更新目录
# def update_doc(docx_file):
#     word=win32com.client.DispatchEx("Word.Application")
#     word.Visible=0
#     word.DisplayAlerts=0
#     doc=word.Documents.Open(docx_file)
#     wd_section=doc.Sections(1)
#     wd_section.Footers(constants.wdHeaderFooterPrimary).PageNumbers.Add(PageNumberAlignment=constants.wdAlignPageNumberCenter) # 添加页码
#     toc_count=doc.TablesOfContents.Count

if __name__ == '__main__':
    # word_path=r'C:\jichengzu\appendix\云平台运行维护及优化完善项目-数据集成月报-202101.docx'
    # wdmc = r'../appendix/云平台运行维护及优化完善项目-数据集成月报-202101.docx'
    wdmc=r"test111.docx"
    dirpath = os.path.abspath(wdmc)
    print(dirpath)
    wordtopdf(dirpath)
