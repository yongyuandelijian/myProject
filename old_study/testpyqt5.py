# 测试pyqt5
# 测试一个例子
import sys
from PyQt5.QtWidgets import QApplication,QWidget,QMessageBox,QMainWindow,QAction,qApp,QLCDNumber,QSlider,QColorDialog,QFrame    # 从基础窗口模块导入必须的控件,消息提示框
from PyQt5.QtWidgets import QToolTip,QPushButton,QLabel,QLineEdit,QTextEdit,QInputDialog    # 导入控件
from PyQt5.QtWidgets import QDesktopWidget,QHBoxLayout,QVBoxLayout,QGridLayout  # 用于调整桌面布局，desktop可以获取屏幕信息的包,比如屏幕大小等
from PyQt5.QtGui import QIcon,QFont,QColor                       # 设置图标,字体的对象，用来在工具类导入的时候使用
from PyQt5.QtCore import QCoreApplication,Qt,QObject,pyqtSignal           # 获取核心功能

# 创建一个信号
class Createsignal(QObject):
    closesignal=pyqtSignal()

# 控件布局依赖于 QWidget类，需要继承他才会有布局,继承QMainWindow才会有菜单，工具栏等等一些的功能
class Example(QWidget):
    '''面向对象oop方式  创建一个学习类'''
    def __init__(self):
        super().__init__()  # 当继承父类后需要自己初始化
        self.cjck()   # 前5章的练习

    def lx6(self):
        '''第6章以后的练习'''
        # 来做一个东西，点击按钮弹出对话框，获取内容然后写入到行控件中
        self.btn=QPushButton('弹出对话框',self)
        self.btn.move(10,50)
        self.qle=QLineEdit(self)
        self.qle.move(10,10)
        self.btn.clicked.connect(self.showdialog)

    def showdialog(self):
        neirong,huifu=QInputDialog.getText(self,'输入框提示','请输入你的名字：') # 返回内容和是否点击了ok键
        if huifu:
            self.qle.setText(neirong)
    def showcolordialog(self):
        pass


    def cjck(self):
        '''创建一个最简单的窗口'''
        # app=QApplication(sys.argv)      # 每个pyqt5必须创建一个程序对象。 sys.argv 是一个参数列表，可以从命令行输入参数
        # window=QWidget()                # qwidget是所有窗口的父类,当继承了这个类之后就不必在自己初始化对象了
        # self.move(300,300)
        # 指定窗口最上角的x,y像素

        self.btn = QPushButton('弹出输入对话框', self)
        # self.btn.move(10, 30)
        self.qle = QLineEdit(self)
        # self.qle.move(10, 10)
        self.btn.clicked.connect(self.showdialog)

        self.btn_chosecolor=QPushButton('选择颜色',self)
        # self.btn.move(10,100)
        self.btn_chosecolor.clicked.connect(self.showcolordialog)
        self.frame=QFrame(self)
        self.frame.setGeometry(50,20,50,20)

        qvl=QVBoxLayout()
        qvl.addWidget(self.qle)
        qvl.addWidget(self.btn)
        qvl.addWidget(self.frame)
        qvl.addWidget(self.btn_chosecolor)
        self.setLayout(qvl)






        # self.xh=Createsignal()  # 用类的属性接收信号实例
        # self.xh.closesignal.connect(self.close) # 将信号连接到关闭事件

        '''
        # 绝对布局，将位置和大小（像素指定下来）
        # lbl1=QLabel('炫酷的计算器窗口欢迎你：',self)
        # lbl1.move(5,5)    # 位置：左，上
        # lbl1.resize(180,30)  # 大小：宽，高
        # lbl2=QLabel('李鹏超',self)
        # lbl2.move(190,5)
        # lbl2.resize(50,30)
        '''
        '''
        # 设置字体提示部分
        QToolTip.setFont(QFont('Bold'))  # 设置提示的字体类型，创建一个传入Qfont定义的字体类型和大小10px

        # 横向盒子布局
        btn_tijiao = QPushButton('提交', self)
        btn_chongzhi = QPushButton('重置', self)
        btn_tuichu = QPushButton('退出', self)
        btn_tuichu.clicked.connect(QCoreApplication.instance().quit)
        btn_tuichu.resize(btn_tuichu.sizeHint())  # 这个看自己情况，重置大小
        btn_tuichu.setToolTip('炫酷的退出！！！')  # 设置鼠标悬浮提示

        # 创建一个水平布局和添加一个伸展因子和两个按钮。两个按钮前的伸展增加了一个可伸缩的空间。这将推动他们靠右显示。
        hbox = QHBoxLayout()
        hbox.addStretch(1)  # 添加一个延伸
        hbox.addWidget(btn_chongzhi)  # 添加控件
        hbox.addWidget(btn_tijiao)
        hbox.addWidget(btn_tuichu)
        # 创建一个垂直布局，并添加伸展因子，让水平布局显示在窗口底部
        vbox = QVBoxLayout()
        vbox.addStretch(1)  # 添加延伸
        vbox.addLayout(hbox)
        # self.setLayout(vbox)  # 这一步才会将布局添加到窗口


        # 定义grid布局，使用文本框和文本域控件
        lbl3 = QLabel('姓名：', self)
        lbl4 = QLabel('工作：', self)
        lbl5 = QLabel('介绍：', self)
        ql1=QLineEdit('李鹏超')
        ql2=QLineEdit('长方体瞬移工程师')
        qt1=QTextEdit('炫酷的长方体瞬移工程师官方认证工程师！！！')
        # 创建布局对象
        gl1=QGridLayout()
        gl1.setSpacing(10)
        # 绑定控件
        gl1.addWidget(lbl3,0,0)
        gl1.addWidget(ql1,0,1)
        gl1.addWidget(lbl4,1,0)
        gl1.addWidget(ql2,1,1)
        gl1.addWidget(lbl5,2,0)
        gl1.addWidget(qt1,2,1,4,1)
        gl1.addWidget(btn_chongzhi,5,1)
        gl1.addWidget(btn_tuichu, 5, 1)
        gl1.addWidget(btn_tijiao, 5, 1)

        self.setLayout(gl1)         # 绑定布局
        '''

        '''使用信号槽，lcd的值会随着滑块的拖动而改变。
        # 创建两个对象,lcd显示和slider滑动开关
        lcd=QLCDNumber(self)
        sld=QSlider(Qt.Horizontal,self) # Horizontal 水平方向

        qvl=QVBoxLayout()
        qvl.addWidget(lcd)
        qvl.addWidget(sld)
        self.setLayout(qvl)
        # 将开关和lcd绑定，将滚动条的valueChanged信号连接到lcd的display插槽。
        sld.valueChanged.connect(lcd.display)
        '''

        '''创建一个lcd和两个按钮，按那个按钮就将按钮自己的控件名称显示到lcd上
        lcd=QLCDNumber(self)
        btn1=QPushButton('按钮1',self)
        btn2=QPushButton('按钮2',self)
        btn1.clicked.connect(self.btnclick)  # 连接到函数中去
        btn2.clicked.connect(self.btnclick)
        lcd.display(1)
        # self.statusBar()    # 创建之后在其他方法内就可以使用状态栏的showmessage方法了

        qhl=QHBoxLayout()
        qhl.addWidget(btn1)
        qhl.addWidget(btn2)

        qvl=QVBoxLayout()
        qvl.addWidget(lcd)
        qvl.addItem(qhl)        # 将两个布局叠加起来
        self.setLayout(qvl)'''








        '''
        # 创建一个格子布局
        gzbj=QGridLayout()  # QGridLayout的实例被创建并设置应用程序窗口的布局
        self.setLayout(gzbj)
        # 我们来定义一个计算器的按钮列表
        name_list = ['清0', '删除', '点赞', '开关',
                 '7', '8', '9', '/',
                 '4', '5', '6', '*',
                 '1', '2', '3', '-',
                 '0', '.', '=', '+']
        # 我们来按照设计定义一个位置的坐标列表
        zuobiao_list=[(i,j)for i in range(5) for j in range(4)]
        # 循环获取
        for mingzi,zuobiao in zip(name_list,zuobiao_list):
            # print(mingzi,zuobiao)
            btn_temp=QPushButton(mingzi)
            gzbj.addWidget(btn_temp,zuobiao[0],zuobiao[1])
            # gzbj.addWidget(btn_temp,*zuobiao)   # * 代表添加任意多个参数,等价于上面的
        '''
        '''
        self.statusBar().showMessage('窗口准备已就绪')  # 用QMainWindow创建状态栏的小窗口。
        # self.statusBar().showMessage('状态已经被修改')  # 修改状态栏

        # 创建菜单栏
        # 创建一个动作
        exitAction=QAction(QIcon('ico/QQPinyin.ico'),'&退出',self)
        exitAction.setShortcut('Ctrl+Q')
        exitAction.setStatusTip('退出程序')     # 悬浮的时候会在状态栏进行提示
        exitAction.triggered.connect(qApp.quit)  # 这个关闭不会被关闭事件捕捉到
        self.statusBar()

        # 创建一个菜单栏
        cdl=self.menuBar()
        filemenu=cdl.addMenu('&文件') # 添加具体菜单
        filemenu.addAction(exitAction)  # 添加菜单下的具体事件

        # 同样的动作可以绑定在工具栏，提供快速访问
        gjl_tc=self.addToolBar('退出')
        gjl_tc.addAction(exitAction)
        '''

        self.setWindowTitle('一个炫酷的窗口标题')  # 设置窗口的标题
        self.setWindowIcon(QIcon('ico/logo.ico'))  # 图标的分辨率不能过小，否则会不能显示
        self.resize(500, 500)           #  重新设置窗口大小，宽，高
        self.ckbj()                     # 调整窗口布局
        self.show()                     # 显示窗口
        # sys.exit(app.exec_())  # sys.exit 可以确保程序干净的退出，由于exec是一个关键字，所以使用下划线，让app的退出接管程序自动退出
    def mousePressEvent(self, QMouseEvent):
        self.xh.closesignal.emit()  # 在鼠标按下的时候将信号发出

    def btnclick(self):
        sender=self.sender()
        message="{kjm}按钮被按下了".format(kjm=sender.text())
        return message

    def keyPressEvent(self, QKeyEvent):
        '''通过重新实现键盘按下事件来处理事件'''
        if QKeyEvent.key()==Qt.Key_Escape:
            self.close()    # 这个退出机制也会触发关闭事件


    def ckbj(self):
        '''调整窗口布局'''
        ck=self.frameGeometry() # 获取窗口几何图形
        pmzx=QDesktopWidget().availableGeometry().center()    # 获取屏幕中心点，也就是字面意思，桌面几何中心
        ck.moveCenter(pmzx)
        self.move(ck.topLeft())

    def closeEvent(self,event):
        '''点击窗口的x时候触发，上面的按钮事件退出则不会触发'''
        huifu=QMessageBox.question(self,'提示','确定要退出吗？',QMessageBox.Yes|QMessageBox.No,QMessageBox.No)
        if huifu==QMessageBox.Yes:
            event.accept()
        else:
            event.ignore()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    lizi=Example()
    sys.exit(app.exec_())
