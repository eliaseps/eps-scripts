#!/bin/bash

## Objetivo: Backup de banco MYSQL por tabelas, ignorando tabelas MYSQL_EXCEPT.
## Criado por: Elias Silva (eps.elias@gmail.com)
## Criado em: 22/04/2014
## Modificado por: N/A
## Modificado em: N/A

#========================#
# CONFIG
#========================#
DATE=$(date +%y%m%d)
TIME=$(date +%H%M)

MYSQL_USER="zabbix"
MYSQL_PASS="12qwaszx"
MYSQL_BASE="zabbix"
MYSQL_EXCEPT='history history_log history_str history_str_sync history_sync history_text history_uint history_uint_sync'

##BKP_DIR="/root/backups"
BKP_DIR="/home/elias.eps/testes"
BKP_TMP="$BKP_DIR/zbx_tmp_${DATE}_${TIME}"
BKP_PREFIX="MySQL_Zabbix"

IGNORE=1
BACKUP=2
test -d "$BKP_TMP" || mkdir -p "$BKP_TMP"

#========================#
# FUNCOES
#========================#

F_Ignore(){
        RESULT=$BACKUP

        for TBL_EXCEPT in $(echo $MYSQL_EXCEPT); do
                test "$1" = "$TBL_EXCEPT" && RESULT="$IGNORE"
        done

        echo $RESULT
}

F_Backup(){
##for TABLE in $(mysql -u$MYSQL_USER -p$MYSQL_PASS -AN -e "show tables from $MYSQL_BASE"); do
for TABLE in $(cat tables.txt); do
        RESULT=$(F_Ignore "$TABLE")
        if test "$RESULT" -eq "$IGNORE"
        then
                echo "$TABLE:IGNORE:"
                continue
        elif test  "$RESULT" -eq "$BACKUP"
        then
                BKP_FILE=$BKP_TMP/$TABLE.sql.bz2
                echo -n "$TABLE:BACKUP:"
##              mysqldump -u$MYSQL_USER -p$MYSQL_PASS $MYSQL_BASE $TABLE | bzip2 > $BKP_FILE 2>> $BKP_LOG ;
                tail -n $(echo $RANDOM | cut -b -3) /var/log/messages | bzip2 > $BKP_FILE
                echo $(du -h "$BKP_FILE"| awk '{print $1}')
        fi
done
}

F_Tar(){
        tar -Pvcf "${BKP_DIR}/${BKP_PREFIX}_${DATE}_${TIME}.tar" "${BKP_TMP}"
}

F_Limpeza(){
        find ${BKP_TMP}/ -type f -name *.bz2 -exec rm -v {} \;
        rmdir ${BKP_TMP}/
}

F_Executa(){
        BKP_LOG="$BKP_DIR/${BKP_PREFIX}_${DATE}_${TIME}.log"
        echo "==== F_Backup" >> $BKP_LOG
        F_Backup >> $BKP_LOG 2>> $BKP_LOG
        echo "==== F_Tar" >> $BKP_LOG
        F_Tar >> $BKP_LOG 2>> $BKP_LOG
        echo "==== F_Limpeza" >> $BKP_LOG
        F_Limpeza >> $BKP_LOG 2>> $BKP_LOG
}


#========================#
# EXECUTA
#========================#

F_Executa


#========================#

#mysqldump db_name table_name | gzip > table_name.sql.bz2
#gunzip < table_name.sql.bz2 | mysql -u username -p db_name
