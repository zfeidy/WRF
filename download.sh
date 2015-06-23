#!/bin/bash
# FTP_SERVER=192.168.10.241
FILECONFIG=/home/NWP/RIXINWRF/source/file.down
DOWNCONFIG=/home/NWP/RIXINWRF/download/download.config
FTP_SERVER=`cat $DOWNCONFIG | grep '^server' | awk -F= '{print $2}'`
FTP_USER=`cat $DOWNCONFIG | grep '^user' | awk -F= '{print $2}'`
FTP_PASS=`cat $DOWNCONFIG | grep '^passwd' | awk -F= '{print $2}'`
FTP_DIR=`cat $DOWNCONFIG | grep '^fdir' | awk -F= '{print $2}'`
FTP_HOUR=`cat $DOWNCONFIG | grep '^hour' | awk -F= '{print $2}'`
FTP_TIMES=`echo $FTP_HOUR | awk -F, '{print NF}'`

while true
do
for y in `seq 1 $FTP_TIMES`
do
THISHOUR=`echo $FTP_HOUR | awk -F, -v fly=$y '{print $fly}'`
#THISHOUR=12
FTP_DDIR=gfs.`date -d '-1day' +%Y%m%d`$THISHOUR
LOC_DIR=`cat $DOWNCONFIG | grep '^ldir' | awk -F= '{print $2}'`
LOC_DDIR=`date -d '-1day' +%Y%m%d`$THISHOUR
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

if [ $y -eq 1 ];then
	#update download file 
	sed -i "/f_down/ s/=.*/= 0/g" $FILECONFIG
	sed -i "/f_start/ s/=.*/= `date +'%Y-%m-%d %H:%M:%S'`/g" $FILECONFIG
	echo "【`date +%Y-%m-%d_%H:%M:%S`】开始下载GFS文件"
	sh tmp.sh && echo "【`date +%Y-%m-%d_%H:%M:%S`】下载$FTP_DDIR文件结束."
	rm -rf tmp.sh

	#Update download file info
	sed -i "/f_down/ s/=.*/= 1/g" $FILECONFIG
	sed -i "/f_end/ s/=.*/= `date +'%Y-%m-%d %H:%M:%S'`/g" $FILECONFIG
	sed -i "/f_file/ s/=.*/= $LOC_DDIR/g" $FILECONFIG
	sed -i "/f_fname/ s/=.*/= `date -d '-1day' +'%Y-%m-%d'`_${THISHOUR}/g" $FILECONFIG
else
	#update download file 
	sed -i "/s_down/ s/=.*/= 0/g" $FILECONFIG
	sed -i "/s_start/ s/=.*/= `date +'%Y-%m-%d %H:%M:%S'`/g" $FILECONFIG
	echo "【`date +%Y-%m-%d_%H:%M:%S`】开始下载GFS文件"
	sh tmp.sh && echo "【`date +%Y-%m-%d_%H:%M:%S`】下载$FTP_DDIR文件结束."
	rm -rf tmp.sh

	#Update download file info
	sed -i "/s_down/ s/=.*/= 1/g" $FILECONFIG
	sed -i "/s_end/ s/=.*/= `date +'%Y-%m-%d %H:%M:%S'`/g" $FILECONFIG
	sed -i "/s_file/ s/=.*/= $LOC_DDIR/g" $FILECONFIG
	sed -i "/s_fname/ s/=.*/= `date -d '-1day' +'%Y-%m-%d'`_${THISHOUR}/g" $FILECONFIG	
fi

done
echo "【`date +%Y-%m-%d_%H:%M:%S`】暂停30分钟后，重新下载文件......"
sleep 30m
done
