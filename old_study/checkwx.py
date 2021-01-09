# 功能描述：批量给好友发送消息一次，检测有哪些好友已经将自己删除
# Author:aaa 20200407
import itchat
import time
import requests

itchat.auto_login(hotReload=True)  # 选择热加载

print('''
提示：
检测结果请在手机上查看，此处只显示检测结果
消息被拒收为被拉黑，需要发送验证消息为被删除
为了保证账号安全，大师的测试2秒刚好，我们保险起见每一次发送间隔5秒，
需要电脑保持网络连接，也不能从手机端将电脑下线
''')

input("按enter键继续！！！")

py=itchat.get_friends(update=True)
hysl=len(py)
# aa=itchat.get_chatrooms(update=True)  # 获取群对象
print("您的好友数量是：",hysl)

'''
微信bug，用自己账户给所有好友发送"ॣ ॣ ॣ"消息，当添加自己为好友时，只有自己能收到此信息，如果没添加自己为好友,没有人能收到此信息
2019年2月更新为 జ్ఞ  ా  这种特殊符号最好复制  经过测试微信好像已经修复了这个问题，于是我们爬取金山词霸的翻译来发送
'''

# 获取金山词霸每日消息
def hqxx():
    url="http://open.iciba.com/dsapi/"  #返回一个json 就和天气那个一样
    wynr=requests.get(url=url)
    hyxx=wynr.json()['note']  # 这里要注意返回的内容，也可能json字典的key回发生变化
    ywxx=wynr.json()['content']
    xiaoxi = "{hyxx}\n{ywxx}\n来自小李爬取别人的每日鸡汤！！！".format(hyxx=hyxx,ywxx=ywxx)
    return xiaoxi



# 全量检测
def qljc():

    # 循环发送消息
    for hy in py:
        '''
        如果需要去除自己使用range(1,hysl)  但是我不需要，于是直接迭代对象
        '''
        itchat.send(hqxx(), toUserName=hy['UserName'])
        print("现在发送的好友是",hy['UserName'])
        # 发送信息速度过快会被微信检测到异常行为。
        time.sleep(5)
    print("检测完毕，请在手机上查看")

# 挑选数量检测
def zdsljc():
    for i in range(2,hysl):  # 跳过自己和媳妇
        itchat.send(hqxx(), toUserName=py[i]['UserName'])
        print("现在发送的好友个数是",i)
        # 发送信息速度过快会被微信检测到异常行为。
        time.sleep(5)
    print("检测完毕，请在手机上查看")

# 如果没有函数和main那必须写上  itchat.run()  来启动

if __name__ == '__main__':
    qljc()