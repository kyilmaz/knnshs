#!/bin/bash -- test
DATE=$(date +%Y%m%d)
COMPANY=name
DBFDIR=/orastage/oracle/oradata/sid
FRADIR=/orastage/oracle/fast_recovery_area
SYSLOG=/var/log
DOMAIN=domain.name
ADMINS=to.go@$DOMAIN
MAILSVR=mail
FROM=$COMPANY.$HOSTNAME@$DOMAIN
LOG=$SYSLOG/knn_dcheck.log

SPRT="____________________________________________________________________________________________________"

cd $LOGDIR

echo -e "$SPRT \n === $HOSTNAME Gunluk Denetim : $(date) ===" > $LOG

#date -d "$(cut -f1 -d' ' /proc/uptime) once boot edildi"  >> $LOG

echo -e "$SPRT \n === Disk Boyutlari ===" >> $LOG
df -PH|awk 'NR>1 {print "Disk > " $6 " :(" $2 ")" " -" " kullanim: ("$3")" " -" " bosyer: ("$4")" " -" " %Kullanim : [> "$5 " <]" }' >> $LOG

echo -e "$SPRT \n === Bellek Detaylari ===" >> $LOG
free -t -g | grep "Mem" | awk '{ print "Toplam Bellek : "$2 " Gb"; print "Kullanilan : "$3" Gb"; print "Bos : "$4" Gb"; }' >> $LOG

echo -e "$SPRT \n === Swap Bellek ===" >> $LOG
free -t -m | grep "Swap" | awk '{ print "Toplam Swap : "$2 " MB"; print "Kullanilan : [>"$3"<] Mb"; print "Bos : "$4" MB";}' >> $LOG

echo -e "$SPRT \n === Kaynak Kullanimlari ===" >> $LOG
ps aux | awk 'NR != 1 {x[$1] += $4} END{ for(z in x) {print z, x[z]"%"}}' >> $LOG

echo -e "$SPRT \n === $DBFDIR dosya boyutlari ===" >> $LOG
ls -h1s --sort=size $DBFDIR >> $LOG
echo -e "$SPRT \n === FRA Alan Bilgisi ===" >> $LOG
du -shc --time $FRADIR/* |sort -rn >> $LOG
echo -e "$SPRT \n === Son Logon Olanlar ===" >> $LOG
tail -4 "/var/log/secure" >> $LOG
echo -e "$SPRT \n === Son 15 Boot Eylemleri ===" >> $LOG
last -Rx |grep boot |head -15 >> $LOG
echo -e "$SPRT \n === TOP 10 Prosesler ===" >> $LOG
ps -eo pcpu,pid,user,args,time | sort -k 1 -r | head -8 >> $LOG
echo -e "$SPRT \n === Oracle Prosesler Top 10s ===" >> $LOG
top -b -n1 -u oracle | head -16 >> $LOG
echo -e "$SPRT \n === Linux Hata Kayitlari ===" >> $LOG
cat $SYSLOG/messages |grep error >> $LOG
echo $SPRT >> $LOG
cat $SYSLOG/messages |grep fail >> $LOG
echo $SPRT >> $LOG
cat $SYSLOG/audit/audit.log |grep fail >> $LOG
dmesg |grep error >> $LOG
echo $SPRT >> $LOG
dmesg |grep fail >> $LOG
echo -e "$SPRT \n === AG Bilgileri ===" >> $LOG
/sbin/ifconfig >> $LOG
echo -e "$SPRT \n === AG Hata ve Zaman Asimi ===" >> $LOG
netstat -s |grep error >> $LOG
echo $SPRT >> $LOG
netstat -s |grep time >> $LOG

echo -e "$SPRT \n === Oracle(PID) Ag Bilgileri ===" >> $LOG
netstat -anp |grep -i esta |grep oracle |grep -v 127.0.0.1 |sort -n -t. -k2 >> $LOG

/usr/bin/mailsend/mailsend -smtp $MAILSVR.$DOMAIN -p 587 -d $DOMAIN -f $FROM -t $ADMINS -sub "$DATE-$COMPANY-$HOSTNAME-Denetim" < "$LOG"

exit
