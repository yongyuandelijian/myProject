"""
功能： 测试多线程
aaa 20210324
"""
import threading

class testThreading(threading.Thread):
    """测试一个多线程"""
    def __init__(self,threadID,name,counter):
        threading.current_thread().__init__(self)
        self.threadID=threadID
        self.name=name
        self.counter=counter

    def run(self):
        print("开始线程"+self.name)
        print("线程在跑。。。")
        print("结束线程"+self.name)

