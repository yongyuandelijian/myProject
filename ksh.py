"""
练习数据可视化
觉得这个东西的确不如网页效果,做本地软件应该还凑合
第二个就是这个感觉很简单,需要用了再来学都来得及,知道有这个数据可视化的工具包就好
"""

import matplotlib.pyplot as plt

# 最简单的展示
# squares=[1,4,7,9,25]
# plt.plot(squares)   # 传入一个列表,讲列表绘制成折线图
# plt.show()  # 将绘制好的图像显示出来


# # 稍微调整样式
# list=[1,54,24,93,22,54]
# plt.plot(list,linewidth=5)
#
# # 设置图标标题,并且给坐标轴加上标签
# plt.title("随便连连图表可视化",fontsize=24)
# plt.xlabel("这是横向坐标的标题",fontsize=14)
# plt.xlabel("这是纵向坐标的标题",fontsize=14)
#
# # 设置刻度标记的大小
# plt.tick_params(axis='both',labelsize=14)
# plt.show()


# Pie chart, where the slices will be ordered and plotted counter-clockwise:
labels = 'Frogs', 'Hogs', 'Dogs', 'Logs'
sizes = [15, 30, 45, 10]
explode = (0, 0.1, 0, 0)  # only "explode" the 2nd slice (i.e. 'Hogs')

fig1, ax1 = plt.subplots()
ax1.pie(sizes, explode=explode, labels=labels, autopct='%1.1f%%',
        shadow=True, startangle=90)
ax1.axis('equal')  # Equal aspect ratio ensures that pie is drawn as a circle.

plt.show()