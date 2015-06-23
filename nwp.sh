#!/bin/bash
HOMEDIR=/home/NWP/RIXINWRF
WRFDIR=${HOMEDIR}/WRF1
#下载的配置文件
SOURCE=${HOMEDIR}/source
CONFIG=${SOURCE}/file.down
#要计算的天数
COMPUTEDAY=7
DATEDIR=`date +%Y%m%d%H`
YEAR=`date +%Y%m%d`
HOUR=`date +%H`
NAME=`date +%H-%m-%d_%H`
DOWN=0
E_NOTROOT=67

#check download nwp file
#检查气象数据文件是否在下载
checkFile(){
	echo "【`date +%Y-%m-%d_%H:%M:%S`】检查下载文件"
	s_down=`cat $CONFIG | grep "s_down" |awk -F'= ' '{print$2}'`
	if [ $s_down -ne 0 ]
	then
		DATEDIR=`cat $CONFIG | grep "s_file" |awk -F'= ' '{print$2}'`
		YEAR=`cat $CONFIG | grep "s_file" |awk -F'= ' '{print$2}' | sed 's/ //g' | cut -c1-8`
		HOUR=`cat $CONFIG | grep "s_file" |awk -F'= ' '{print$2}' | sed 's/ //g' | cut -c9-10`
		NAME=`cat $CONFIG | grep "s_fname" |awk -F'= ' '{print$2}' | sed 's/ //g'`
		DOWN=2
		echo "【`date +%Y-%m-%d_%H:%M:%S`】下载的文件目录为:$DATEDIR"
	else
		f_down=`cat $CONFIG | grep "f_down" |awk -F'= ' '{print$2}'`
		if [ $f_down -ne 0 ]
		then
			DATEDIR=`cat $CONFIG | grep "f_file" |awk -F'= ' '{print$2}'`
			YEAR=`cat $CONFIG | grep "f_file" |awk -F'= ' '{print$2}' | sed 's/ //g' | cut -c1-8`
			HOUR=`cat $CONFIG | grep "f_file" |awk -F'= ' '{print$2}' | sed 's/ //g' | cut -c9-10`
			NAME=`cat $CONFIG | grep "f_fname" |awk -F'= ' '{print$2}' | sed 's/ //g'`
			DOWN=1
			echo "【`date +%Y-%m-%d_%H:%M:%S`】下载的文件目录为:$DATEDIR"
		else
			echo '【`date +%Y-%m-%d_%H:%M:%S`】文件未下载成功！等待下载中...'
			sleep 1m
			checkFile
		fi
	fi
}

#config namelist.wps file
#配置操作文件
MAX_DOM=4
#HOUR=00
CONFIGFILE=${WRFDIR}/WPS/namelist.wps
config(){
	printf "【`date +%Y-%m-%d_%H:%M:%S`】配置【namelist.wps】开始************************************\n"
	START=\'`date -d "$YEAR" +%F`_${HOUR}:00:00\'
	END=\'`date -d "$YEAR +${COMPUTEDAY}day" +%F`_${HOUR}:00:00\'
	#echo $START $END
	sed -i "/max_dom/ s/=.*,/= $MAX_DOM,/g" $CONFIGFILE
	sed -i "/start_date/ s/=.*,/= $START, $START, $START, $START,/g" $CONFIGFILE
	sed -i "/end_date/ s/=.*,/= $END, $END, $END, $END,/g" $CONFIGFILE
	printf "【`date +%Y-%m-%d_%H:%M:%S`】配置【namelist.wps】完毕！**********************************\n"
}

#update namelist.input
INPUTFILE=${WRFDIR}/WRFV3/test/em_real/namelist.input
#如果计算三天的话，运行时间设置为3*24小时
#如需其他参数设置，在这个地方初始化，然后在下面用sed命令更新
RUN_HOURS=$((${COMPUTEDAY}*24))
updateInput(){
	printf "【`date +%Y-%m-%d_%H:%M:%S`】更新【namelist.input】开始************************************\n"
	START_YEAR=`date -d "$YEAR" +%Y`
	START_MONTH=`date -d "$YEAR" +%m`
	START_DAY=`date -d "$YEAR" +%d`
	# START_MINUTE=`date +%M`
	# START_HOUR=`date +%H`
	# START_SECOND=`date +%S`
	START_HOUR=$HOUR
	START_MINUTE=00	
	START_SECOND=00
	END_YEAR=`date -d "$YEAR +${RUN_HOURS}hour" +%Y`
	END_MONTH=`date -d "$YEAR +${RUN_HOURS}hour" +%m`
	END_DAY=`date -d "$YEAR +${RUN_HOURS}hour" +%d`
	# END_HOUR=`date -d "+${RUN_HOURS}hour" +%H`
	# END_MINUTE=`date -d "+${RUN_HOURS}hour" +%M`
	# END_SECOND=`date -d "+${RUN_HOURS}hour" +%S`
	# END_HOUR=$HOUR
	END_HOUR=$HOUR
	END_MINUTE=00
	END_SECOND=00
	sed -i "/run_hours/ s/=.*/= $RUN_HOURS,/g" $INPUTFILE
	sed -i "/start_year/ s/=.*/= $START_YEAR,$START_YEAR,$START_YEAR,$START_YEAR,/g" $INPUTFILE
	sed -i "/start_month/ s/=.*/= $START_MONTH,$START_MONTH,$START_MONTH,$START_MONTH,/g" $INPUTFILE
	sed -i "/start_day/ s/=.*/= $START_DAY,$START_DAY,$START_DAY,$START_DAY,/g" $INPUTFILE
	sed -i "/start_hour/ s/=.*/= $START_HOUR,$START_HOUR,$START_HOUR,$START_HOUR,/g" $INPUTFILE
	sed -i "/start_minute/ s/=.*/= $START_MINUTE,$START_MINUTE,$START_MINUTE,$START_MINUTE,/g" $INPUTFILE
	sed -i "/start_second/ s/=.*/= $START_SECOND,$START_SECOND,$START_SECOND,$START_SECOND,/g" $INPUTFILE
	sed -i "/end_year/ s/=.*/= $END_YEAR,$END_YEAR,$END_YEAR,$END_YEAR,/g" $INPUTFILE
	sed -i "/end_month/ s/=.*/= $END_MONTH,$END_MONTH,$END_MONTH,$END_MONTH,/g" $INPUTFILE
	sed -i "/end_day/ s/=.*/= $END_DAY,$END_DAY,$END_DAY,$END_DAY,/g" $INPUTFILE
	sed -i "/end_hour/ s/=.*/= $END_HOUR,$END_HOUR,$END_HOUR,$END_HOUR,/g" $INPUTFILE
	sed -i "/end_minute/ s/=.*/= $END_MINUTE,$END_MINUTE,$END_MINUTE,$END_MINUTE,/g" $INPUTFILE
	sed -i "/end_second/ s/=.*/= $END_SECOND,$END_SECOND,$END_SECOND,$END_SECOND,/g" $INPUTFILE
	printf "【`date +%Y-%m-%d_%H:%M:%S`】更新【namelist.input】结束************************************\n"
}

#Link Grib
WPSDIR=${WRFDIR}/WPS
#Grid
grid(){
	cd $WPSDIR || echo "【`date +%Y-%m-%d_%H:%M:%S`】目录错误，无法打开!"
	printf "【`date +%Y-%m-%d_%H:%M:%S`】【GeoGrib.exe】开始************************************\n"
	cd $WPSDIR && ./geogrid.exe
	#Link 文件
	printf "【`date +%Y-%m-%d_%H:%M:%S`】【Link WPS】开始************************************\n"
	cd $WPSDIR || echo "【`date +%Y-%m-%d_%H:%M:%S`】目录$WPSDIR不存在,无法打开！"
	cd $WPSDIR && ./link_grib.csh $SOURCE/$DATEDIR/gfs.t${HOUR}z.pgrbf* ./ && echo "Link_Grid GFS文件成功"
	printf "【`date +%Y-%m-%d_%H:%M:%S`】【Link WPS】结束************************************\n"
	printf "【`date +%Y-%m-%d_%H:%M:%S`】【UnGrib.exe】开始************************************\n"
	cd $WPSDIR && ./ungrib.exe
	printf "【`date +%Y-%m-%d_%H:%M:%S`】【MetGrid.exe】开始************************************\n"
	cd $WPSDIR && ./metgrid.exe
	printf "【`date +%Y-%m-%d_%H:%M:%S`】【Met WPS】结束************************************\n"
}

#Real Data
REALDIR=${WRFDIR}/WRFV3/test/em_real/
realAndWrf(){
	printf "【`date +%Y-%m-%d_%H:%M:%S`】【Real WPS】开始,当前时间：`date +%Y-%m-%d_%H:%M:%S`************************************\n"
	cd $REALDIR && ln -s $WPSDIR/met_em.d* ./
	cd $REALDIR && ./real.exe
	mpiexec -n 6 ./wrf.exe
	printf "【`date +%Y-%m-%d_%H:%M:%S`】【Real WPS】结束,当前时间：`date +%Y-%m-%d_%H:%M:%S`************************************\n"
}

#Analysis Data And BackUp解析数据
WRFOUTDIR=${HOMEDIR}/wrfout
MAPCONFIG=${WRFOUTDIR}/mapping.config
ANACONFIG=${WRFOUTDIR}/analysis.config
SIZE=`cat $MAPCONFIG | grep size | awk -F'= ' '{print $2}'`
NCNAME=`cat $MAPCONFIG | grep ncname | awk -F'= ' '{print $2}'`
TXTNAME=`cat $MAPCONFIG | grep txtname | awk -F'= ' '{print $2}'`
analysisData(){
	s=$(($SIZE+2))
	printf "【`date +%Y-%m-%d_%H:%M:%S`】NCL解析数据开始！************************************\n"
	for i in $(seq 3 $s)
	do
		#首先把数据移动到tmp临时目录，然后在backup目录下面备份
		echo "【`date +%Y-%m-%d_%H:%M:%S`】${WRFDIR}/WRFV3/test/em_real/wrfout_d0${i}_${NAME}*"
		if [ -f ${WRFDIR}/WRFV3/test/em_real/wrfout_d0${i}_${NAME}* ]
		then
			echo "【`date +%Y-%m-%d_%H:%M:%S`】`cd ${WRFDIR}/WRFV3/test/em_real/ && ls wrfout_d0${i}_${NAME}* -l`"
			mv ${WRFDIR}/WRFV3/test/em_real/wrfout_d0${i}_${NAME}* ${HOMEDIR}/tmp/ && echo "文件wrfout_do${i}_${NAME}*移动成功!"
		else
			echo "【`date +%Y-%m-%d_%H:%M:%S`】文件wrfout_d0${i}_${NAME}*不存在，可能已经移动到tmp目录下面!"
		fi
		#引入外部变量，获取电场简写名称
		fname=`echo $TXTNAME | awk -F',' -v fly=$i '{print $fly}'`
		#获取时间
		echo "【`date +%Y-%m-%d_%H:%M:%S`】检查文件${HOMEDIR}/tmp/wrfout_d0${i}_${NAME}*是否已经存,不存在去bacukup目录下查找！"
		if [ -f ${HOMEDIR}/tmp/wrfout_d0${i}_${NAME}* ]
		then
			sname=`cd ${HOMEDIR}/tmp && ls wrfout_d0${i}_${NAME}* | sed 's/-//g' | sed 's/ //g' | sed 's/://g' |sed 's/_//g' | cut -c10-19`
			#文件备份与重命名
			echo "【`date +%Y-%m-%d_%H:%M:%S`】复制${HOMEDIR}/tmp/wrfout_d0${i}_${NAME}*到${HOMEDIR}/backup/目录下"
			cp ${HOMEDIR}/tmp/wrfout_d0${i}_${NAME}* ${HOMEDIR}/backup/
			echo "【`date +%Y-%m-%d_%H:%M:%S`】重命名${HOMEDIR}/tmp/wrfout_d0${i}_${NAME}*为${HOMEDIR}/tmp/${fname}${sname}.nc"
			mv ${HOMEDIR}/tmp/wrfout_d0${i}_${NAME}* ${HOMEDIR}/tmp/${fname}${sname}.nc
		else
			if [ -f ${HOMEDIR}/backup/wrfout_d0${i}_${NAME}* ]
			then
				echo "【`date +%Y-%m-%d_%H:%M:%S`】在bacukup中发现wrfout_d0${i}_${NAME}*，开始解析..."
				cp  ${HOMEDIR}/backup/wrfout_d0${i}_${NAME}* ${HOMEDIR}/tmp/
				sname=`cd ${HOMEDIR}/tmp && ls wrfout_d0${i}_${NAME}* | sed 's/-//g' | sed 's/ //g' | sed 's/://g' |sed 's/_//g' | cut -c10-19`
				mv ${HOMEDIR}/tmp/wrfout_d0${i}_${NAME}* ${HOMEDIR}/tmp/${fname}${sname}.nc
			else
				echo "【`date +%Y-%m-%d_%H:%M:%S`】文件wrfout_d0${i}_${NAME}*不存在，可能没有解析完成，等待解析中..."
				sleep 2m
				#重新开始解析
				analysisData
			fi
		fi
		sed -i "/wrfoutname/ s/=.*/= ${fname}${sname}.nc/g" $ANACONFIG
		sed -i "/txtpath/ s/=.*/= ${fname}${sname}.txt/g" $ANACONFIG
		sed -i "/start/ s/=.*/= $sname/g" $ANACONFIG
		sed -i "/tt/ s/=.*/= $[RUN_HOURS*4+1]/g" $ANACONFIG
		cd ${HOMEDIR}/wrfout && ncl try.ncl
		cd ${HOMEDIR}/tmp && rm -rf *
		catToWpd && echo "【`date +%Y-%m-%d_%H:%M:%S`】生成WPD文件成功！************************************\n"
		if [ $DOWN -eq 2 ]
		then
			sed -i "/s_down/ s/=.*/= 0/g" $CONFIG && echo "【`date +%Y-%m-%d_%H:%M:%S`】重置$CONFIG中文件下载属性s_down************************************\n"
		fi
		if [ $DOWN -eq 1 ]
		then
			sed -i "/f_down/ s/=.*/= 0/g" $CONFIG && echo "【`date +%Y-%m-%d_%H:%M:%S`】重置$CONFIG中文件下载属性f_down************************************\n"
		fi
	done
	printf "【`date +%Y-%m-%d_%H:%M:%S`】NCL解析数据结束！************************************\n"
}

#解析成wpd数据
catToWpd(){
	WPDDIR=${HOMEDIR}/wpd
	LAT=`cat $MAPCONFIG | grep clat | awk -F'= ' '{print $2}'`
	LON=`cat $MAPCONFIG | grep clon | awk -F'= ' '{print $2}'`
	HIGH=`cat $MAPCONFIG | grep high | awk -F'= ' '{print $2}'`
	TIME=`cat $CONFIG | grep "f_file" |awk -F'= ' '{print$2}' | sed 's/ //g'`
	#TIME=2013050712
	s=$(($SIZE+2))
	for i in $(seq 3 $s)
	do
        	fname=`echo $TXTNAME | awk -F',' -v fly=$i '{print $fly}'`
        	lat=`echo $LAT | awk -F',' -v fly=$i '{print $fly}'`
        	lon=`echo $LON | awk -F',' -v fly=$i '{print $fly}'`
        	high=`echo $HIGH | awk -F',' -v fly=$i '{print $fly}'`
        	cat $WRFOUTDIR/$fname$TIME.txt | grep "$lat" | grep "$lon" | grep " $high " > $WPDDIR/$fname$TIME.WPD
	done
}

#Delete Data
deleteData(){
	printf "【`date +%Y-%m-%d_%H:%M:%S`】删除数据开始************************************\n"
	rm ${WPSDIR}/FILE:*
	rm ${WPSDIR}/GRIBFILE.*
	rm ${WPSDIR}/met_em.d*
	rm ${WPSDIR}/*.nc
	rm ${WRFDIR}/WRFV3/test/em_real/rsl.*
	rm ${WRFDIR}/WRFV3/test/em_real/met_em.d*
	rm ${WRFDIR}/WRFV3/test/em_real/wrfinput_d*
	rm ${WRFDIR}/WRFV3/test/em_real/wrfrst_d0*
	rm ${WRFDIR}/WRFV3/test/em_real/wrfout_d01*
	rm ${WRFDIR}/WRFV3/test/em_real/wrfout_d02*
	printf "【`date +%Y-%m-%d_%H:%M:%S`】删除数据成功************************************\n"
}

#主程序
ROOT_UID=`cat /etc/passwd | grep '^NWP' | awk -F: '{print $3}'`
MY_ID=`id -u`
#ROOT_UID=0
echo $MY_ID
while true
do
	if [ $MY_ID -ne $ROOT_UID ]
	then
		echo "【`date +%Y-%m-%d_%H:%M:%S`】只有【NWP】用户才有操作权限!"
		exit E_NOTROOT
	else
		echo "【`date +%Y-%m-%d_%H:%M:%S`】数据解析开始！"
	fi
	#Delete 数据
	deleteData
	checkFile
	#配置文件
	config
	#Grid文件
	grid
	#更新输入文件
	updateInput
	#Real文件
	realAndWrf
	#Analysis Data解析文件
	analysisData 
	sleep 12h
done
