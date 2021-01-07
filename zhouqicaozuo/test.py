# coding: cp936


import win32gui
import win32con
import time


class TestTaskbarIcon:
    def __init__(self):
        # ע��һ��������
        wc = win32gui.WNDCLASS()
        hinst = wc.hInstance = win32gui.GetModuleHandle(None)
        wc.lpszClassName = "PythonTaskbarDemo"
        wc.lpfnWndProc = {win32con.WM_DESTROY: self.OnDestroy, }
        classAtom = win32gui.RegisterClass(wc)
        style = win32con.WS_OVERLAPPED | win32con.WS_SYSMENU
        self.hwnd = win32gui.CreateWindow(classAtom, "Taskbar Demo", style,
                                          0, 0, win32con.CW_USEDEFAULT, win32con.CW_USEDEFAULT,
                                          0, 0, hinst, None)
        hicon = win32gui.LoadIcon(0, win32con.IDI_APPLICATION)
        nid = (self.hwnd, 0, win32gui.NIF_ICON, win32con.WM_USER + 20, hicon, "Demo")
        win32gui.Shell_NotifyIcon(win32gui.NIM_ADD, nid)

    def showMsg(self, title, msg):
        # ԭ����ʹ��Shell_NotifyIconA���������װ���Shell_NotifyIcon����
        # �ݳ��ǲ���win32gui structure, ��ϡ���Ϳ�������.
        # ����Ա�ԭ����.
        nid = (self.hwnd,  # ���
               0,  # ����ͼ��ID
               win32gui.NIF_INFO,  # ��ʶ
               0,  # �ص���ϢID
               0,  # ����ͼ����
               "TestMessage",  # ͼ���ַ���
               msg,  # ������ʾ�ַ���
               5,  # ��ʾ����ʾʱ��
               title,  # ��ʾ����
               win32gui.NIIF_INFO  # ��ʾ�õ���ͼ��
               )
        win32gui.Shell_NotifyIcon(win32gui.NIM_MODIFY, nid)

    def OnDestroy(self, hwnd, msg, wparam, lparam):
        nid = (self.hwnd, 0)
        win32gui.Shell_NotifyIcon(win32gui.NIM_DELETE, nid)
        win32gui.PostQuitMessage(0)  # Terminate the app.


if __name__ == '__main__':
    t = TestTaskbarIcon()
    t.showMsg("�����µ��ļ������¼�鿴", "Mr a2man!")
    time.sleep(5)
    win32gui.DestroyWindow(t.hwnd)