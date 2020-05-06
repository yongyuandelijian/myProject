# 功能描述：根据鸡和兔的头数量计算鸡兔各自的数量
# Author:aaa 20200305

def js(toushu,jaoshu):
    jsl=0
    tsl=0
    jsl=(toushu*4-jaoshu)/2
    tsl =toushu-jsl
    return jsl,tsl

if __name__ == '__main__':
    toushu=int(input("请输入总头数"))
    jiaoshu=int(input("请输入脚总数"))
    jsl,tsl=js(toushu,jiaoshu)
    print("兔子的数量是{tsl}，鸡的数量是{jsl}".format(tsl=tsl,jsl=jsl))
