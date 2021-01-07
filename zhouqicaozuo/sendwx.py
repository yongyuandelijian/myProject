# 功能描述：批量发送微信消息
# Author:aaa 20200407
# 遇到的问题：碰到获取群对象不稳定或者获取不到的情况，打开手机微信找到目标，并将“保存到通讯录”的开关打开，再运行程序正常
from wxpy import *
from threading import Timer
import time

class mtrywjtx(object):
    bot = Bot(cache_path=True)  # 初始化一个对象并且保存缓存

    # 发送到群内的消息
    @bot.register()  # 用于注册消息配置
    def sendwx(send_friends, qdx, xiaoxi_ld, xiaoxi_qun):
        """传入一个消息和要发送的群，将消息发给批量好友"""
        try:
            if qdx:
                for friend in qdx:
                    qld=friend.search('小女孩的大叔')  # 从群对象中找到领导  #你朋友的微信名称，不是备注，也不是微信帐号。
                    print("反馈人员", qld)
                    friend.send(xiaoxi_qun)
            else:
                print("群对象未获取到")
        except:
            send_friends[0].send("发送消息异常！！！")
        finally:
            send_friends[0].send(xiaoxi_ld)  # 给领导一个反馈，先不反馈

    TEMP_NUM = 0

    def pdsj(xs, fz,jgsj):  # 发送的小时，发送的分，发送的间隔秒数
        '''逻辑：如果时间未到则提示时间然后等待，如果时间到未获取到群对象，那么三分钟后重新调用,五次后如果仍然为获取到对象，则提示管理员手动转发'''
        if time.localtime(time.time()).tm_hour == xs and time.localtime(time.time()).tm_min < fz:
            send_friends = mtrywjtx.bot.search('小女孩的大叔', sex=MALE)  # 获取自己对象
            qdx = mtrywjtx.bot.groups().search(r'大数据云平台')  # 根据群组名称获取群对象的列表,和名字一样，无法过滤出含有特殊符号的
            xiaoxi_ld = r"消息发送成功！！！"
            xiaoxi_qun = r"@所有人，请各省运维人员检查分发库冗余文件情况，然后点击【https://docs.qq.com/form/fill/DUkhVTkh1SFhwVlht?_w_tencentdocx_form=1&from=groupmessage】按要求填写文档"
            print(send_friends, qdx)
            if qdx:
                mtrywjtx.sendwx(send_friends, qdx, xiaoxi_ld, xiaoxi_qun)
                sys.exit(-1)  # 发送完毕，退出程序
            else:
                mtrywjtx.TEMP_NUM = mtrywjtx.TEMP_NUM + 1
                xiaoxi_ld = "群对象第{num}未找到，三分钟后重试！！！".format(num=mtrywjtx.TEMP_NUM)
                jgsj=180
                time.sleep(jgsj)
                mtrywjtx.pdsj(xs, 30,jgsj)
                if mtrywjtx.TEMP_NUM >= 5:  # 未找到群对象获取5次，如果还是未获取到那就时间超过
                    xiaoxi_ld = xiaoxi_qun + "\n重新获取5次依旧未获取到对象，程序退出，请手动转发以上消息"
                    mtrywjtx.sendwx(send_friends, qdx, xiaoxi_ld, xiaoxi_qun)
                    sys.exit(-2)
        else:
            print("时间未到，现在是：{xiaoshi}:{fenzhong}".format(xiaoshi=time.localtime(time.time()).tm_hour,
                                                         fenzhong=time.localtime(time.time()).tm_min))
        t = Timer(jgsj, mtrywjtx.pdsj,(xs,10,jgsj))  # 单位是秒，如果想要每天是86400
        t.start()


if __name__ == '__main__':
    # qdx = mtrywjtx.bot.groups().search(r'省项目组工作')
    # print(qdx)
    mtrywjtx.pdsj(16,10,600)  # 16点十分以前发送,每十分钟探查一次


    # send_friends[0].send_image("E:\税收分类.png")

    # 发送文本消息：friend.send('文本消息')
    # 发送图片消息：friend.send_image('图片消息.jpg')
    # 发送视频消息：friend.send_video('视频消息.mov')
    # 发送文件消息：friend.send_file('文件消息.zip')
    # 以动态的方式发送图片：friend.send('@img@图片消息.jpg')
    # sendwx("测试测试",send_friends)
    # embed()