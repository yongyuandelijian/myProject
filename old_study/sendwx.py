# 功能描述：批量发送微信消息
# Author:aaa 20200407
from wxpy import *
from threading import Timer
import time

bot=Bot(cache_path=True)  # 初始化一个对象并且保存缓存

# print(send_friend)

# 微信好友地域分布
# from pyecharts.charts.basic_charts import map  # from pyecharts import Map 旧版本可能回是这样的目录，注意看目录

from pyecharts.charts import Map
import webbrowser  # 文档https://docs.python.org/3/library/webbrowser.html
from collections import defaultdict
from pyecharts import options as opts


# 省份分布  模仿
def sffb():
    friends = bot.friends(update=True)
    dy=defaultdict(lambda :0)   # defaultdict的作用是在于，当字典里的key不存在但被查找时，返回的不是keyError而是一个默认值
    for f in friends:
        if '\u9fa5'>=f.province>='\u4e00':  # 如果省份是汉字就保留，否则就舍弃，因为在中国地图上也不会显示
            dy[f.province] += 1
    attr=dy.keys()
    value=dy.values()
    dx=[list(dx1) for dx1 in zip(attr,value)]  # zip将可迭代的对象打包成一个一个的元组 如果各个迭代器的元素个数不一致，则返回列表长度与最短的对象相同
    print(dx)


    # 地图部分
    m1=Map()
    m1.add(series_name="微信好友",data_pair=dx,maptype="china",name_map={"key":"value"},is_map_symbol_show=True)
    m1.set_global_opts(
        title_opts=opts.TitleOpts(title="小李的微信好友",subtitle="2020-04-10"),  # 设置标题和副标题在左侧
        visualmap_opts=opts.VisualMapOpts(is_piecewise=True,max_=250)  # 是否分段,以及分段的最大值
    )
    m1.render('province.html')
    webbrowser.open('province.html')


# 陕西省内各个城市分布  自己改进后
def sxcsfb():
    friends=bot.friends(update=True)
    dd1=defaultdict(int)   # 如果调用字典的key不存在的时候，默认value为0
    for hy in friends:
        # print(hy.city)
        if '\u9fa5' >= hy.city >= '\u4e00':  # 如果省份是汉字就保留，否则就舍弃，因为在中国地图上也不会显示
            city=hy.city+"市"   # 必须要加，不加会名字识别不到
            dd1[city]+=1   # 每次进来如果key相同则进行累加
    sj=[list(a) for a in zip(dd1.keys(),dd1.values())]

    print(sj)

    # 地图部分
    m2=Map()
    m2.add(series_name="微信好友",data_pair=sj,maptype="陕西",is_map_symbol_show=True)
    m2.set_global_opts(
        title_opts=opts.TitleOpts(title="陕西好友分布",subtitle=time.strftime("%Y-%m-%d %H:%M:%S",time.localtime(time.time()))),
        visualmap_opts=opts.VisualMapOpts(is_piecewise=True,is_calculable=True,max_=180)
    )
    m2.render("./kshwy/map_sxcsfb.html")
    webbrowser.open("E:\study\kshwy\map_sxcsfb.html")

# 使用百度api进行展示
from pyecharts.charts import BMap
# from pyecharts.globals import ChartType,SymbolType
def bdapi():
    friends=bot.friends(update=True)
    dd1=defaultdict(int)   # 如果调用字典的key不存在的时候，默认value为0
    for hy in friends:
        # print(hy.city)
        if '\u9fa5' >= hy.city >= '\u4e00':  # 如果省份是汉字就保留，否则就舍弃，因为在中国地图上也不会显示
            city=hy.city+"市"   # 必须要加，不加会名字识别不到
            dd1[city]+=1   # 每次进来如果key相同则进行累加
    sj=[list(a) for a in zip(dd1.keys(),dd1.values())]
    # 地图部分
    BD_AK="xC9wlIKWG31GZwZ87jFBGO6RycDZf7Ue"
    MR_ZX=[108.9550557300,34.3247934100]    # 定义地图的默认中心位置
    m3=BMap()
    # 进去的地图中心点 可以在网址查询 http://www.gpsspg.com/maps.htm 但是这里有一点需要注意，地图给出来的维度和经度，这里的顺序是经纬度，需要调整下
    m3.add_schema(
        baidu_ak=BD_AK,
        center=MR_ZX,
        zoom=8  # 缩放程度
    )
    m3.add(
        series_name="",
        data_pair=sj,
        label_opts=opts.LabelOpts("{b}"),
    )
    m3.set_global_opts(
        title_opts=opts.TitleOpts("百度API展示微信好友分布"),
        visualmap_opts=opts.VisualMapOpts(is_piecewise=True,max_=180,pos_bottom=40), # 最后一个是设置提示距离底端的距离，防止百度的log将数据挡住
    )
    m3.render("./kshwy/map_bdapi.html")
    webbrowser.open("E:\study\kshwy\map_bdapi.html",autoraise=True)

# 发送到群内的消息
@bot.register()   # 用于注册消息配置
def sendwx(send_friends,qdx,xiaoxi_ld,xiaoxi_qun):
    """传入一个消息和要发送的群，将消息发给批量好友"""
    try:
        for friend in qdx:
            # qld=friend.search('强子')  # 从群对象中找到领导  #你朋友的微信名称，不是备注，也不是微信帐号。
            # print("群领导", friend)
            friend.send(xiaoxi_qun)
            send_friends[0].send(xiaoxi_ld)  # 给领导一个反馈
        t = Timer(10, sendwx, (send_friends, qdx, xiaoxi_ld, xiaoxi_qun))  # 单位是秒，如果想要每天是86400
        t.start()
    except:
        send_friends[0].send("发送消息异常！！！")



# @bot.register(chats=qdx)
# def recv_send_msg(recv_msg,qld):
#      print('收到的消息：',recv_msg)
#      # recv_msg.sender   是群这个对象
#      if recv_msg.member == qld:
#          #这里不用recv_msg.render 因为render是群的名字
#          # recv_msg.forward(bot.file_helper,prefix='老板发言: ')
#          return '老板说的好有道理，深受启发'

# Timer(interval, function, args=[], kwargs={})
# 　　interval: 指定的时间
# 　　function: 要执行的方法
# 　　args/kwargs: 方法的参数

if __name__ == '__main__':
    sffb()
    time.sleep(10)  # 停十秒
    input("调试让输出界面暂停排查错误，如果发布删除！！！！")


    # send_friends = bot.search('强子', sex=MALE)  # 获取朋友对象
    # qdx = bot.groups().search('装逼')  # 根据群组名称获取群对象的列表,和名字一样，无法过滤出含有特殊符号的
    # xiaoxi_ld = "强哥群内消息已经发送-发给领导的反馈的消息"
    # xiaoxi_qun = "每10秒发给群里的测试消息-发给群里的消息"
    # print(send_friends,qdx)
    # sendwx(send_friends,qdx,xiaoxi_ld,xiaoxi_qun)


    # send_friends[0].send_image("E:\税收分类.png")

    # 发送文本消息：friend.send('文本消息')
    # 发送图片消息：friend.send_image('图片消息.jpg')
    # 发送视频消息：friend.send_video('视频消息.mov')
    # 发送文件消息：friend.send_file('文件消息.zip')
    # 以动态的方式发送图片：friend.send('@img@图片消息.jpg')
    # sendwx("测试测试",send_friends)
    # embed()