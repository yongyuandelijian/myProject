import socket
from enum import Enum

# 常量使用大写字母来命名规范
CS = 10
# 但是上面其实本质上还是变量，我们可以使用枚举来限制常量不被修改
month=Enum("month",(1,2,3,4))
class Aaa_socket(object):  # 一般来说类名为大写字母开头
    """描述必须放在第一行，用三个注释符号"""

    def __init__(self,url,port):
        self.url=url   # 如果要设置为私有属性，我们可以设置为self.__url=url这样在类的外部无法访问，如果只是为了让外部无法修改，但是
        self.__port=port

    # 如果想让外部可以访问
    def get_port(self,port):
        return port
    # 如果想要外部可以修改,这样可以对外部传入的修改做一些限制，如果直接定义为外部的，则不能被控制
    def set_port(self,port):
        self.__port=port

    # 需要说明的是在Python中，变量名类似__xxx__的，也就是以双下划线开头，并且以双下划线结尾的，是特殊变量，特殊变量是可以直接访问的，不是private变量，
    # 所以，不能用__name__、__score__这样的变量名

    """在类中定义的函数只有一点不同，就是第一个参数永远是实例变量self，并且，调用时，不用传递该参数"""
    def client(self): # 客户端
        s=socket.socket(socket.AF_INET,socket.SOCK_STREAM)  # 创建一个socket对象，传入参数，ip4协议和使用面向流的TCP协议
        s.connect((self.url,port)) # 创建连接,端口号小于1024的是Internet标准服务的端口，端口号大于1024的，可以任意使用。
        s.send(b'GET / HTTP/1.1\r\nHost: www.sina.com.cn\r\nConnection: close\r\n\r\n') # 上面做的链接和请求到的数据都会存在socket对象里面
        nr=[] # 存储每次的内容
        while True:
            mc=s.recv(1024) # 每次接收1k
            if len(mc)>1:
                nr.append(mc) # 如果内容不为空则一直追加，否则应该结束跳出循环
            else:
                break
        sj=b"".join(nr)
        s.close()  # 接收完毕关闭链接
        header,html=sj.split(b"\r\n\r\n",1)
        return header,html

class subclass(object,Aaa_socket): # python支持多重继承来简化继承关系，通过多重继承，一个子类就可以同时获得多个父类的所有功能
    pass


if __name__ == '__main__':
    url="www.sina.com.cn"
    port=80
    aaa=Aaa_socket(url,port)  # 初始化一个对象
    # print(aaa.client()[0].decode("utf-8"))  # 未增加decode的时候所有输出都是一行，增加之后，换行符等字段就开始有效果了
    # print(aaa.client()[1].decode("utf-8"))  # 使用对象来获取类的属性和方法
    # print(aaa.get_port(port))
    # print(type(aaa),isinstance(aaa,Aaa_socket),isinstance(aaa,(Aaa_socket,list,tuple)))   # 获取和判断对象的类型，而且还可以判断是不是元组中的某一个
    # 展示对象的所有方法和属性，仅仅把属性和方法列出来是不够的，配合getattr()、setattr()以及hasattr()，我们可以获取，设置，判断对象的属性，一般情况下，如果知道存在就直接写，不会去判断
    print(aaa.__doc__,dir(aaa),getattr(aaa,"time",404))  # 获取对象的属性，如果不存在则使用默认值
