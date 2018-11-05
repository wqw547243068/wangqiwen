=======================
cube灌数据模块
=======================

配置文件格式
================

全局配置
------------------

全局配置位于[global]配置区中， 配置项包括：

total_job_number 任务总是
retry_interval   检测任务是否满足运行条件的时间间隔，单位为分钟
output_path      输出数据根路径
root_code_path   运行机上代码根路径
hadoop_client    运行机上hadoop客户端路径

单个任务配置
-------------------------

单个任务的配置位于[jobN]中配置，N为任务的序号. 配置项包括:

job_name                任务名
input_number            输入数据个数
input_N                 第N个输入数据的路径
input_ready_1           第N个输入数据可用标记文件/路径
code_path               执行的代码
detect_start_time       开始检测任务是否可以运行时刻， 格式HHMM
detect_wait_mins        数据超时时间，单位：分钟
delay_after_ready       任务满足运行条件后，慢启动的等待时间
job_success_flag        任务成功后，数据可用的检查路径

**NOTE** 目前的实现，为了保证串行执行模式能够正常工作，如果任务B依赖于任务A产生
  的数据，任务B的配置应该放在任务A的配置之后。


运行
================

运行路径
-------------------
需要在模块安装路径下运行命令

运行命令
------------------
   python bin/schedule.py [options] [tasks]

帮助
------------------
   python bin/schedule.py --help

运行参数
------------------

  -h, --help            帮助
  -f, --disable_timeout 关闭数据超时机制
  -d DATE, --date=DATE  处理最近数据的日期
  -n TOTAL_DAY, --total_day=TOTAL_DAY    连续处理的数据的天数

  -s, --sequence_run    串行运行任务
  -x, --fix_data        采用补数据逻辑
  -p PIPELINE, --pipeline=PIPELINE  流程名称，同时也是日志名称
  -r RETRY, --retry=RETRY  任务重试的次数
  -R --rerun               重跑任务
  -w RETRY_SLEEP, --retry_sleep=RETRY_SLEEP  任务重试的间隔时间，单位: 秒
  -a, --run_force       强制立即运行任务，不管任务是否成功产生过和数据是否完全准备好
  -c CONFIG_FILE, --config_file=CONFIG_FILE  指定配置文件
  -K --kill           杀掉任务
  -S --signal         发zk数据信号

正常例行
------------------
   python bin/schedule.py

运行某个数据
-------------------
  python bin/schedule.py -d 20121007

重新运行任务
------------------
  python bin/schedule.py -f -R -n 2 holmes  session_forum bae mergeOneDay

串行补数据
-------------------
  python bin/schedule.py -x -s -f -n 7 -p patch_data 20121007

  串行补20121001-20121007的数据

并行补数据
-------------------
  python bin/schedule.py -x -f -n 7  -p patch_data 20121007

  并行补20121001-20121007的数据
