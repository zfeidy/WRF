#!/bin/bash
DOWNCONFIG=/home/NWP/RIXINWRF/download/download.config
FTP_SERVER=`cat $DOWNCONFIG | grep '^server' | awk -F= '{print $2}'`
FTP_USER=`cat $DOWNCONFIG | grep '^user' | awk -F= '{print $2}'`
FTP_PASS=`cat $DOWNCONFIG | grep '^passwd' | awk -F= '{print $2}'`
FTP_DIR=`cat $DOWNCONFIG | grep '^fdir' | awk -F= '{print $2}'`

for y in `seq 1 11`
do
	THISHOUR=12
	FTP_DDIR=gfs.`date -d "-${y}day" +%Y%m%d`$THISHOUR
	LOC_DIR=`cat $DOWNCONFIG | grep '^ldir' | awk -F= '{print $2}'`
	LOC_DDIR=`date -d "-${y}day" +%Y%m%d`$THISHOUR
	DOW_DAYS=`cat $DOWNCONFIG | grep '^days' | awk -F= '{print $2}'`

	#del tmp.sh
	rm -rf tmp.sh

	if [ ! -x "$LOC_DIR/$LOC_DDIR" ]; then
		echo "【`date +%Y-%m-%d_%H:%M:%S`】新建目录$LOC_DIR/$LOC_DDIR"
		mkdir "$LOC_DIR/$LOC_DDIR"
	else
		echo "【`date +%Y-%m-%d_%H:%M:%S`】目录已经存在，检查GFS文件是否已经下载"
		num=`ls $LOC_DIR/$LOC_DDIR -l | wc -l`
		if [ $num -ge $(($DOW_DAYS*4)) ]; then
			echo "【`date +%Y-%m-%d_%H:%M:%S`】目录$LOC_DIR/$LOC_DDIR下面的GFS文件已经下载，不需要再下载"
			continue
		fi
	fi

	echo "【`date +%Y-%m-%d_%H:%M:%S`】下载GFS$FTP_DDIR文件开始......"

cat >> tmp.sh <<HEAD
ftp -n -v << Fly 2>&1
open $FTP_SERVER
user $FTP_USER $FTP_PASS
cd ${FTP_DIR}${FTP_DDIR}
lcd $LOC_DIR/$LOC_DDIR
tick 1024
prompt off
HEAD

for x in `seq 0 $(($DOW_DAYS*4))`;
do
#	echo "开始下载第$x个文件"
	day=$(($x*6))
	if [ $day -lt 10 ]
	then
		day=0$day
	fi
	#all_gfs[x]=gfs.t${FTP_HOUR}z.pgrbf${day}.grib2
	#echo ${all_gfs[@]}
	echo "mget gfs.t${THISHOUR}z.pgrbf${day}.grib2" >> tmp.sh
#	echo "第$x个文件下载完成"
done

cat >> tmp.sh <<END
close
bye
Fly
END

sh tmp.sh && echo "【`date +%Y-%m-%d_%H:%M:%S`】下载$FTP_DDIR文件结束."
rm -rf tmp.sh

done
