# from urllib import request
import urllib.request
from urllib.parse import quote
import string

jqrjk='http://api.qingyunke.com/api.php?key=free&appid=0&msg='
# http://api.qingyunke.com/api.php?key=free&appid=0&msg=  ai机器人API地址
def main():
    # 循环处理，客户端发送的聊天信息
    while True:
        # 定义一个url地址 格式为：API地址 + 用户聊天输入发送的语句内容
        url =  jqrjk+ input("请输入您要发送的消息")
        # urllib.request.urlopen不支持中英文混合的字符串。
        # 所以应使用urllib.parse.quote进行转换。
        # 方法quote的参数safe表示可以忽略的字符。
        s = quote(url, safe=string.printable)
        # string.printable表示ASCII码第33～126号可打印字符
        # 其中第48～57号为0～9十个阿拉伯数字；65～90号为26个大写英文字母，97～122号为26个小写英文字母
        # 其余的是一些标点符号、运算符号等。
        # 所以必须设置这个safe参数

        # 使用urllib.request请求URL，获得一个响应
        with urllib.request.urlopen(s) as response:
            html = response.read()
            # 将获取到的响应内容进行解码，并将json字符串内容转换为python字典格式
            # 通过下标取到机器人回复的内容
            print(eval(html.decode("utf-8"))["content"])

import requests
def dyjqr():
    while True:
        wt=input("请输入您要发送的消息")
        url = jqrjk + wt
        # response=requests.get(url=url)
        with requests.get(url=url) as response:
            jh = response.text  # 消息头部、响应状态码和响应正文时 使用.headers、.status_code、.text方法，方法名称与功能本身相对应
            hf=eval(jh)["content"]  #eval执行一个字符串表达式返回这个字符串表达式的执行结果
            fstz(wt,hf)



# win10消息提示框
from win10toast import ToastNotifier
import psutil
import time
from threading import Timer
def fstz(wt,hf):
    # print(psutil.boot_time()/60/60)
    # kjsj = time.strftime("%H小时%M分钟%S秒", time.localtime(psutil.boot_time()))
    # xiaoxi = "内容，每两个小时应该喝水一次！！！,电脑已经开机:{kjsj}".format(kjsj=kjsj)
    toaster=ToastNotifier()
    # 有图标
    # toaster.show_toast(title="喝水提醒标题",msg=xiaoxi,icon_path="./ico/logo.ico",duration=5,threaded=True)  # duration持续秒数
    # toaster.show_toast(title="喝水提醒",msg=xiaoxi,icon_path=None,duration=5,threaded=False) # 其实不指定图标只是使用系统图标而已
    toaster.show_toast(title=wt, msg=hf, icon_path="./ico/logo.ico", duration=5, threaded=True)
    xx=(wt,hf) # 有参数在传入参数元组，如果是只有一个参数，后面这个逗号还是需要的，否则会把第一个参数当成多个分隔
    t = Timer(5,fstz,xx)
    t.start()

if __name__ == '__main__':
    dyjqr()