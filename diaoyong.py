# ecoding:utf-8
from zhouqicaozuo import createword,createword_zlz
import time
import re
import os

if __name__ == '__main__':
    starttime = time.time()
    ny = '202102'
    lx = 'jcz'
    root_dir = os.path.abspath(".")
    if re.match('[2][0][0-9]{2}', ny[:4]) or re.match('[0,1][0-9]', ny[4:]):
        if lx=='jcz':
            temp_path = r"appendix/云平台运行维护及优化完善项目-数据集成月报-{ny}.docx".format(ny=ny)
            createword.scword(ny,root_dir,temp_path).scword()
        elif lx=='zlz':
            temp_path = r"appendix/任务运行情况月报-{ny}.docx".format(ny=ny)
            createword_zlz.scword(ny,root_dir,temp_path).scword()
    else:
        print("年月输入异常，请处理后再执行脚本")
    print("生成完毕,消耗时间：", round(time.time() - starttime, 2))