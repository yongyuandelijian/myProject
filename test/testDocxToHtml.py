#ecoding:utf-8
import docx
from docx2html import convert
import HTMLParser
def  docx2html(docx_name,new_name):
    """
    :docx转html
    """
    try:
        #读取word内容
        doc = docx.Document(docx_name,new_name)
        data = doc.paragraphs[0].text
        # 转换成html
        html_parser = HTMLParser.HTMLParser()
        #使用docx2html模块将docx文件转成html串，随后你想干嘛都行
        html = convert(new_name)
        #docx2html模块将中文进行了转义，需要将生成的字符串重新转义
        return html_parser.enescape(html)
    except:
        pass
if __name__ == '__main__':
    docx2html('f:/test.docx','f:/test1.docx')