import datetime
from datetime import timedelta

def gen_dates(b_date, days):  # 传入开始时间和起始日期之间的天数,返回开始日期增加天数后的日期
    for i in range(days):
        yield b_date + timedelta(days=1) * i  # yield在下次调用的时候不需要在从头开始

def get_month_list1(start_date, end_date):
    if start_date is not None:
        start = datetime.datetime.strptime(start_date, "%Y%m%d")
    if end_date is None:
        end = datetime.date.today() # 如果没有结束日期默认为当前日期,使用today效率会高一些
    else:
        end = datetime.datetime.strptime(end_date, "%Y%m%d")
    month_list = []
    for d in gen_dates(start, ((end - start).days + 1)):  # 实际天数=差额+1
        month=d.strftime("%Y%m%d").__str__()[:6]
        if month not in month_list:
            month_list.append(month)
    return month_list
