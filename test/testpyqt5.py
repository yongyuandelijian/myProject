# 测试pyqt5
# 测试一个例子
import sys
from PyQt5.QtWidgets import QApplication,QWidget    # 从基础窗口模块导入必须的控件
from PyQt5.QtGui import QIcon                       # 设置图标

class Example():
    '''面向对象oop方式  创建一个学习类'''
    def cjjcck(self):
        '''创建一个最简单的窗口'''
        app=QApplication(sys.argv)      # 每个pyqt5必须创建一个程序对象。 sys.argv 是一个参数列表，可以从命令行输入参数
        window=QWidget()                # qwidget是所有窗口的父类
        # window.resize(300,150)          # 指定窗口大小
        window.move(300,300)            # 指定窗口最上角的x,y像素
        window.setWindowTitle('一个炫酷的窗口标题')  # 设置窗口的标题
        window.setWindowIcon('../img/')
        window.show()                   # 显示窗口
        sys.exit(app.exec_())           # sys.exit 可以确保程序干净的退出，由于exec是一个关键字，所以使用下划线，让app的退出接管程序自动退出

    def szxtb(self):
        '''创建一个窗口并设置图标'''

        pass


if __name__ == '__main__':
    lizi=Example()
    lizi.cjjcck()