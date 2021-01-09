from selenium import webdriver
import os
import time
'''
# 功能：从网易云音乐获取自己长得爱好表单，主要是随便练习一下
# 实现思路：首先点击右上角的登录，然后点击自己的qq图像按钮，然后在获取音乐名称清单
# 确定程序入口的位置
# 确定首页数据的位置和url地址
# 实现翻页和程序停止的判断
# aaa 20200816
'''

class GetMusicList():
    """获取网易云音乐歌曲列表"""
    def __init__(self):
        """初始化必须穿入驱动路径和地址获取到一个浏览器对象"""
        self.start_url="http://music.163.com/#/discover/playlist"
        self.chrome_driver=u"C:\Program Files (x86)\Google\Chrome\Application\chromedriver.exe"
        os.environ["webdriver.chrome.driver"] = self.chrome_driver  # 引入chromedriver.exe
        self.browser = webdriver.Chrome(self.chrome_driver)
        # driver = webdriver.Firefox()  # 其他浏览器
        # driver = webdriver.Ie()

    def autoLogin(self):
        """自动登录"""
        self.browser.get(self.start_url)
        time.sleep(5) # 打开之后停顿一下
        # 寻找按钮
        dlan=self.browser.find_elements_by_tag_name("a")
        for a in dlan:
            print(a.text)




        # ele_login=self.browser.find_element_by_link_text("登录")
        # elements=self.browser.find_elements_by_tag_name("a")
        # for a in elements:
        #     print(a.text)
        # ele_login2=self.browser.find_element_by_link_text("登录")
        # print(ele_login)


    def get_content_list(self):
        """获取音乐清单"""
        self.browser.get(self.start_url)
        time.sleep(5)  # 打开之后停顿一下
        # 切换到iframe
        self.browser.switch_to.frame("g_iframe")
        # 获取到自己想要的分类
        xzfl = self.browser.find_element_by_id("cateToggleLink")
        xzfl.click()
        time.sleep(1)
        # dls=self.browser.find_elements_by_tag_name("dl")
        dls=self.browser.window_handles
        print(dls)
        for dl in dls:
            fl = dl.get_attribute("f-cb")
            print("1111",fl)
            print("2222",fl.text)
            print("3333",fl.tag_name)


        # for i in fl:
        #     print(">>>>",i.text)
        # pass



if __name__ == '__main__':
    gml=GetMusicList()
    gml.get_content_list()




#在百度搜索框中输入关键字"python"并提交
# browser.find_element_by_id("kw").send_keys("网易云音乐")
# time.sleep(2)
# browser.find_element_by_id("su").click()

# class 等于 OP_LOG_LINK c-text c-text-public c-text-mult c-gap-icon-left normal-gf-icon 是官网

#关闭浏览器
#browser.quit()