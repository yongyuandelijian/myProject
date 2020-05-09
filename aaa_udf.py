from odps.udf import annotate


@annotate("bigint,bigint->bigint")
class test(object):

    def evaluate(self, arg0, arg1):
        return
