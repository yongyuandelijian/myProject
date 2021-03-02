import win32com
from win32com.client import Dispatch #constants也是从这里加载不过用不上

#调用word程序，不在前台显示
w = win32com.client.Dispatch("Word.Application")
w.Visible = 0
w.DisplayAlerts = 0

#打开一个word文档
doc = w.Documents.Open(r'E:\work\test\test.docx')

#获取总页数
# w.ActiveDocument.Repaginate()
pages = w.ActiveDocument.ComputeStatistics(2)
print(pages)

#保存并关闭
doc.SaveAs('test.docx')
doc.Close()
