#! /bin/bash

chmod -R +x /home/kingbase/Server

if [ ! -e "/opt/Kingbase/ES/V8/data/SYS_VERSION" ];then
  mkdir -p /opt/Kingbase/ES/V8/data
  echo ${KINGBASE_SYSTEM_PASSWORD-123456} > /home/kingbase/password
  echo "init param --> /home/kingbase/Server/bin/initdb -U SYSTEM --pwfile=/home/kingbase/password -E UTF8 -D /opt/Kingbase/ES/V8/data ${EXTEND_INIT_PARAM}"
  /home/kingbase/Server/bin/initdb -U SYSTEM --pwfile=/home/kingbase/password -E UTF8 -D /opt/Kingbase/ES/V8/data ${EXTEND_INIT_PARAM}
  if [ -n "${ORA_INPUT_EMPTYSTR_ISNULL}" ]; then
    sed -i "s/ora_input_emptystr_isnull.*/ora_input_emptystr_isnull = ${ORA_INPUT_EMPTYSTR_ISNULL}/" /opt/Kingbase/ES/V8/data/kingbase.conf
  fi
fi

/home/kingbase/Server/bin/kingbase -D /opt/Kingbase/ES/V8/data/