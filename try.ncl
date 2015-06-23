load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
;载入ncl库
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
begin
	APATH = systemfunc("cat analysis.config | grep 'wrfoutname'|awk -F'=' '{print $2}'|sed 's/ //g'")
	print("../tmp/" + APATH)
	a = addfile("../tmp/" + APATH,"r")
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;读入wrfout.nc文件
;1、当wrf计算完成后，生成的wrfout文件需要cp到存档文件夹以及供ncl解析气象要素的临时文件夹两个地方
;2、cp到ncl解析气象要素的临时文件夹后，相应所需要的wrfout文件需要改名为wrfout_d0*.nc
;3、建议将addfile("./wrfout.nc","r")中的./wrfout.nc作为变量，每次需要的时候到控制文件中读取，相应的语法为APATH =systemfunc("echo $WRF_temp_PATH")
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	T = (wrf_user_getvar(a,"T2",-1) - 273.15) 
	u10 = wrf_user_getvar(a,"U10",-1) 
	v10 = wrf_user_getvar(a,"V10",-1)
	sw = wrf_user_getvar(a,"SWDOWN",-1) 
	sh = wrf_user_getvar(a,"QVAPOR",-1) 
	pr = (wrf_user_getvar(a,"P",-1)+ wrf_user_getvar(a,"PB",-1) )*0.01
	uw = wrf_user_getvar(a,"U",-1) 
	vw = wrf_user_getvar(a,"V",-1)
	st = (wrf_user_getvar(a,"TSK",-1) - 273.15)
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;uw及vw为u及v方向上的风速
;T2为2米高温度
;u10及v10为10米高度上uv方向的风速
;sh为水汽混合比
;pr为大气压
;st为地表温度
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	gx = stringtointeger(systemfunc("cat analysis.config | grep 'gx'|awk -F'=' '{print $2}'|sed 's/ //g'"))
	gy = stringtointeger(systemfunc("cat analysis.config | grep 'gy'|awk -F'=' '{print $2}'|sed 's/ //g'"))
	sx = stringtointeger(systemfunc("cat analysis.config | grep 'sx'|awk -F'=' '{print $2}'|sed 's/ //g'"))
	sy = stringtointeger(systemfunc("cat analysis.config | grep 'sy'|awk -F'=' '{print $2}'|sed 's/ //g'"))
	tt = stringtointeger(systemfunc("cat analysis.config | grep 'tt'|awk -F'=' '{print $2}'|sed 's/ //g'"))
	th = 4
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;gx是wrf的网格格点中我们需要的x方向上的个数，gy我们需要的y方向上的个数
;sx是wrf计算结果中对应我们需要的位置在domain中的x方向起始点所在位置，sy为y方向起始点所在位置
;tt是时间序列上要素的总数量，tt的计算方法为：如果计算时长为72小时，每隔15分钟取一次风速，tt=72*4+1
;th高度序列的总个数
;建议将这些参数做成变量存在控制文件，当每次开始计算之前到控制文件中取出相应的参数，gx = stringtoitteger(systemfunc("echo $gard_number_in_x"))
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	lons = new((/gx/),float)
	do n = sx,gx+sx-1
		lons(n-sx) = n
	end do
	lats = new((/gy/),float)
	do m = sy,gy+sy-1
		lats(m-sy) = m
	end do
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
	res = 0
	loc = wrf_user_ij_to_ll(a,lons,lats,res)
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;将wrf的gard格点转换为经纬度
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	shn = new((/tt,th,gy,gx/),float)
	prn = new((/tt,th,gy,gx/),float)
	un = new((/tt,th,gy,gx/),float)
	vn = new((/tt,th,gy,gx/),float)
	swn = new((/tt,th,gy,gx/),float)
	stn = new((/tt,th,gy,gx/),float)
	Tn = new((/tt,th,gy,gx/),float)
	hn = new((/th/),integer)
	;tn = new((/tt/),integer)
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;定义sh\u\v\st\高度\时间\pr\T的四维数组
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	do k = 0,tt-1
		do j = sy,sy+gy-1
			do i = sx,sx+gx-1
				un(k,0:0,j-sy,i-sx) = (/u10(k,j,i)/)
				vn(k,0:0,j-sy,i-sx) = (/v10(k,j,i)/)
				Tn(k,0:0,j-sy,i-sx) = (/T(k,j,i)/)
				shn(k,0:0,j-sy,i-sx)= (/sh(k,1:1,j,i)/)
				prn(k,0:0,j-sy,i-sx)= (/pr(k,1:1,j,i)/)
				stn(k,0:0,j-sy,i-sx)= (/st(k,j,i)/)
				swn(k,0:0,j-sy,i-sx)= (/sw(k,j,i)/)
	 
				un(k,1:3:1,j-sy,i-sx) = (/uw(k,3:5:1,j,i)/)
				vn(k,1:3:1,j-sy,i-sx) = (/vw(k,3:5:1,j,i)/)
				Tn(k,1:3:1,j-sy,i-sx) = (/T(k,j,i)/)
				shn(k,1:3:1,j-sy,i-sx)= (/sh(k,3:5:1,j,i)/)
				prn(k,1:3:1,j-sy,i-sx)= (/pr(k,3:5:1,j,i)/)
				stn(k,1:3:1,j-sy,i-sx)= (/st(k,j,i)/)
			end do
		end do
		;tn(k)=((floattointeger(k/4))%24)*100+(k%4)*15
	end do
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;将所需高度的要素赋予相应的数组
;设定时间间隔tn(k)=((floattointeger(k/4))%24)*100+(k%4)*15需要做以下处理：tn(k)=((stringtointeger(systemfunc("echo $WRF_start_HOUR"))+floattointeger(k/4))%24)*100+(k%4)*15，建议将$WRF_start_HOUR（wrf开始计算的时间）做成变量每次从控制文件中读取。
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	hgt = (/10,30,50,70/)
	;hgt = (/10,20,50,65/) 
	;mydate = stringtointeger(systemfunc("date -d '20160416'+'%Y%m%d %h%M%s'"))
	startdate = systemfunc("cat analysis.config | grep 'start'|awk -F'=' '{print $2}'|sed 's/ //g' | cut -c1-8")
	starthour = systemfunc("cat analysis.config | grep 'start'|awk -F'=' '{print $2}'|sed 's/ //g' | cut -c9-10")
	;print(startdate)
	;print(starthour)
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;设定高度和日期，stringtointeger(20130416)建议做成变量从控制文件中读取，例如stringtointeger(systemfunc("echo $WRF_start_DATE"))
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
txtpath = systemfunc("cat analysis.config | grep 'txtpath'|awk -F'=' '{print $2}'|sed 's/ //g'")
mns= gx*gy*th*tt
pms= new(mns,"string")
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;建议将"1.txt" 做成变量从控制文件中读取
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	mn = 0
	flag = 0
	do t=0,tt-1
		;if(t%96.eq.0)
			;mydate = stringtointeger(systemfunc("date -d '" + flag + " day' +'%Y%m%d'"))
			_mm = (t+(stringtointeger(starthour)+8)*4)*15
			;print(_mm)
			mydate = systemfunc("date -d '" + startdate +" " + _mm + "minute' +'%Y-%m-%d %H:%M:%S'")
			;flag = flag + 1
		;end if
		do k=0,th-1
			do j=0,gy-1
				do i=0,gx-1
					pms(mn) = sprintf("%10.4f", loc(0,i))
					pms(mn) = pms(mn) + sprintf("%10.4f", loc(1,j))
					pms(mn) = pms(mn) + sprinti("%5i", hgt(k))
					pms(mn) = pms(mn) + "     " + mydate
					;pms(mn) = pms(mn) + sprinti("%5.4i", tn(t))
					xu = un(t,k,j,i)
					yu = vn(t,k,j,i)
					pms(mn) = pms(mn) + sprintf("%10.2f ",xu) 
					pms(mn) = pms(mn) + sprintf("%10.2f ",yu)
					pms(mn) = pms(mn) + sprintf("%10.2f ",(xu*xu + yu*yu)^0.5)
					pms(mn) = pms(mn) + sprintf("%10.2f ",Tn(t,k,j,i))
					pms(mn) = pms(mn) + sprintf("%10.2f ",shn(t,k,j,i))
					;pms(mn) = pms(mn) + sprintf("%10.2f ",swn(t,k,j,i))
					pms(mn) = pms(mn) + sprintf("%10.2f ",prn(t,k,j,i))
					pms(mn) = pms(mn) + sprintf("%10.2f ",stn(t,k,j,i))
					mn = mn + 1
				end do
			end do
		end do
	end do
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
asciiwrite (txtpath , pms)
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
end
