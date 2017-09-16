# ! /bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
KNIFE_HOME=${SCRIPT_DIR}/..
START_LOG=${KNIFE_HOME}/knife_start.log

[ -f ${START_LOG} ] || touch ${START_LOG}

procnum=`ps -ef|grep "beam"|grep -v grep|wc -l`
if [ $procnum -eq 0 ]
then
    ${SCRIPT_DIR}/knife-server controller -detached >> ${START_LOG} 2>&1
    echo `date +%Y-%m-%d` `date +%H:%M:%S`  "restart knife" >>${START_LOG}
else
    echo `date +%Y-%m-%d` `date +%H:%M:%S`  "knife running" >>${START_LOG}
fi
