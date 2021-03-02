import win32gui
import win32con
import time

# 功能： windows提示消息
class indowsmessage:
    def __init__(self):
        # 注册一个窗口类
        wc=win32gui.WNDCLASS()
