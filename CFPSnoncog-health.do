*============================================================*
**       		CFPS 
**Goal		:  The impact of noncognitive on health  
**Data		:    CFPS2018
**Author	:  	 ZhangYi zhangyiceee@163.com 15592606739
**Created	:  	 20211201
**Last Modified: 202009
*============================================================*
	capture	clear
	capture log close
	set	more off
	set scrollbufsize 2048000
	capture log close 
	


	cd "/Users/zhangyi/Documents/data/CFPS/real_cfps"
	global cleandir "/Users/zhangyi/Desktop/Research/CFPS/noncog_health/cleandata"
	global output "/Users/zhangyi/Desktop/Research/CFPS/noncog_health/output"
	global workingdir "/Users/zhangyi/Desktop/Research/CFPS/noncog_health/working"



*控制点
*2010年数据内控
	use "CFPS2010/cfps2010adult_201906.dta",clear
*自控点	 
	codebook qn506
	tab1 qn506 qn507 qn501 qn502  qn504 qn503 qn505,m
	codebook qn505
*c_qn506 c_qn507 c_qn501 c_qn502  c_qn504 需要反向处理
*c_qn503 c_qn505
	foreach x of varlist qn506 qn507 qn501 qn502  qn504 qn503 qn505{
		clonevar  c_`x' =`x' if `x'>=1 &`x'<=5
		recode c_`x' (3=4)(4=5)(5=3)
	}
	*参照文献将部分的进行反向处理
	foreach x of varlist c_qn506 c_qn507 c_qn501 c_qn502 c_qn504 {
		recode `x'  (1=5)(2=4)(3=3)(4=2)(5=1)
	}

	foreach x of  varlist c_qn506 c_qn507 c_qn501 c_qn502 c_qn504 c_qn503 c_qn505{
		recode `x' (5=2)(4=1)(3=0)(2=-1)(1=-2)
	}
	center c_qn506 c_qn507 c_qn501 c_qn502 c_qn504 c_qn503 c_qn505 ,prefix(z_)

	egen incontrol =rowmean(z_c_qn506 z_c_qn507 z_c_qn501 z_c_qn502 z_c_qn504 z_c_qn503 z_c_qn505)
	label var incontrol "内控综合得分"
	tab incontrol,m
	kdensity incontrol

*经济学季刊的内外控点,拿总分做一次,拿内外控再做一次
	todummy incontrol ,values(75) percentile
	rename d_incontrol intrenal
	label var intrenal "内控倾向"
	tab intrenal

	todummy incontrol ,values(25) percentile
	sort incontrol d_incontrol
	tab d_incontrol

	recode d_incontrol (1=0)(0=1)
	rename d_incontrol external
	label var external "外控倾向"
	
	gen neutral =0 if incontrol!=.
	replace neutral =1 if intrenal==0 & external==0
	label var neutral "中性倾向"


*Predetermined characteristics ：性别、民族、婚姻状况、父母受教育程度、家庭收入、省份固定效应、年龄的固定效应
*Gender 
	codebook gender
*年龄
	gen age=qa1age 
	label var age "年龄"
	tab age,m
*民族
	label list qa5code
	tab qa5code,m
	gen han=.
	replace han=1 if qa5code==1
	replace han=0 if qa5code>1
	replace han=. if  qa5code==.
	tab han,m
*婚姻状况：将未婚作为对照组
	tab qe1_best,m
	codebook qe1_best
	gen married=0 if qe1_best >0
	replace married=1 if qe1_best==2|qe1_best==3
	label var married "已婚或同居"

	gen divorce=0 if qe1_best >0
	replace divorce=1 if qe1_best==4
	label var divorce "离异"

	gen widow=0 if qe1_best >0
	replace widow=1 if qe1_best==5
	label var widow "丧偶"

*受教育年限 
	tab cfps2010eduy_best,m
	gen eduyear =cfps2010eduy_best if cfps2010eduy_best>0
	label var eduyear "受教育年限"


*父亲受教育年限
	tab tb4_a_f,m
	gen faeduyear=.
	replace faeduyear=0 if tb4_a_f==1
	replace faeduyear=6 if tb4_a_f==2
	replace faeduyear=9 if tb4_a_f==3
	replace faeduyear=12 if tb4_a_f==4
	replace faeduyear=15 if tb4_a_f==5
	replace faeduyear=16 if tb4_a_f==6
	replace faeduyear=19 if tb4_a_f==7
	replace faeduyear=22 if tb4_a_f==8
	replace faeduyear=26 if tb4_a_f==9
	label var faeduyear "父亲受教育年限"
*母亲受教育年限
	tab tb4_a_m,m
	label list tb4_a_m
	gen moeduyear=.
	replace moeduyear=0 if tb4_a_m==1
	replace moeduyear=6 if tb4_a_m==2
	replace moeduyear=9 if tb4_a_m==3
	replace moeduyear=12 if tb4_a_m==4
	replace moeduyear=15 if tb4_a_m==5
	replace moeduyear=16 if tb4_a_m==6
	replace moeduyear=19 if tb4_a_m==7
	replace moeduyear=22 if tb4_a_m==8
	replace moeduyear=26 if tb4_a_m==9
	label var moeduyear "母亲受教育年限"

*家庭收入
*和家庭收入相匹配

*控制变量

	global control "gender han married divorce widow eduyear faeduyear moeduyear "
	global control1 " han married divorce widow eduyear faeduyear moeduyear "

*被解释变量：BMI
*BMI
	tab1 qp2 qp1,m
	gen height=qp1/100 if qp1 >=0
	label var height "身高m"
	gen weight=qp2/2 if qp2 >=0
	label var weight "体重kg"
	gen bmi=weight/(height^2)
	label var bmi "身体质量指数"
*超重
	gen overweight =0 if bmi>0
	replace overweight=1 if bmi>=25
	label var overweight "超重"
*肥胖
	gen obese =0 if bmi>0
	replace obese=1 if bmi>=30
	label var obese "肥胖"
*机制变量

*吸烟、锻炼
	tab qq2,m
	codebook qq2
	gen smoking =.
	replace smoking =1 if qq2==1
	replace smoking =0 if qq2==0
	label var smoking "是否吸烟 "
*锻炼 上星期锻炼了几次
	tab qp8,m
	gen exercise=.
	replace exercise=1 if qp8 >=1 &qp8 <=20
	replace exercise=0 if qp8==0
	label var exercise "过去一周是否锻炼"
	tab exercise,m


*饮食 Healthy Eating Index ：饮食多样性
	tab1 qp901_s_1 qp901_s_2 qp901_s_3 qp901_s_4 qp901_s_5 qp901_s_6 qp901_s_7 qp901_s_8 qp901_s_9,m
	codebook qp901_s_2
	foreach x of varlist qp901_s_1 qp901_s_2 qp901_s_3 qp901_s_4 qp901_s_5 qp901_s_6 qp901_s_7 qp901_s_8 qp901_s_9{
		gen c_`x'=`x'
		recode c_`x' (-8 =0) (1 2 3 4 5 6 7 8=1) (78 -1=.)
	}
	egen health_eating=rowtotal(c_qp901_s_1 c_qp901_s_2 c_qp901_s_3 c_qp901_s_4 c_qp901_s_5 c_qp901_s_6 c_qp901_s_7 c_qp901_s_8 c_qp901_s_9)
	replace health_eating=. if qp901_s_1==78
	tab health_eating,m

*删掉变量存在缺失的样本
	egen miss=rowmiss(height weight bmi overweight obese $control age provcd smoking exercise health_eating)
	label var miss "样本缺失变量的个数"
	tab miss,m
	keep if miss==0

*描述性统计分析
	logout ,excel tex save("$output/sum") replace :sum  height weight bmi overweight obese age  $control


*仅省份的固定效应,年龄按照控制变量出现
	areg weight incontrol age  $control  ,absorb(provcd)
	outreg2 using "$output/self_bmi_fe",adjr2 keep(incontrol age $control) bdec(3) addtext(Provience,Yes) tex excel replace
	areg weight intrenal external age  $control  ,absorb(provcd)
	outreg2 using "$output/self_bmi_fe",adjr2 keep(intrenal external age $control) bdec(3) addtext(Provience,Yes) tex excel append
	
	areg bmi incontrol age $control  ,absorb(provcd)
	outreg2 using "$output/self_bmi_fe",adjr2 keep(incontrol age $control) bdec(3) addtext(Provience,Yes) tex excel append
	areg bmi intrenal external age $control  ,absorb(provcd)
	outreg2 using "$output/self_bmi_fe",adjr2 keep(intrenal external age $control) bdec(3) addtext(Provience,Yes) tex excel append
	
	areg overweight incontrol age  $control  ,absorb(provcd)
	outreg2 using "$output/self_bmi_fe",adjr2 keep(incontrol age $control) bdec(3) addtext(Provience,Yes) tex excel append 
	areg overweight intrenal external age  $control  ,absorb(provcd)
	outreg2 using "$output/self_bmi_fe",adjr2 keep(intrenal external age $control) bdec(3) addtext(Provience,Yes) tex excel append 
	
	areg obese incontrol age  $control  ,absorb(provcd)
	outreg2 using "$output/self_bmi_fe",adjr2 keep(incontrol age $control) bdec(3) addtext(Provience,Yes) tex excel append 
	areg obese intrenal external age  $control  ,absorb(provcd)
	outreg2 using "$output/self_bmi_fe",adjr2 keep(intrenal external age $control) bdec(3) addtext(Provience,Yes) tex excel append 
	
*对自评健康的影响

	
	

*不同性别
*分性别的影响
	areg weight incontrol age  $control1 if gender==1 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(incontrol  age $control1) bdec(3) addtext(Provience,Yes,Male,Yes) tex excel replace
	areg weight incontrol age  $control1 if gender==0 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(incontrol  age $control1) bdec(3) addtext(Provience,Yes,Male,No) tex excel append
	areg weight intrenal external age  $control1 if gender==1 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(intrenal external age $control1) bdec(3) addtext(Provience,Yes,Male,Yes) tex excel append
	areg weight intrenal external age  $control1 if gender==0 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(intrenal external age $control1) bdec(3) addtext(Provience,Yes,Male,No) tex excel append
	areg bmi incontrol age  $control1 if gender==1 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(incontrol  age $control1) bdec(3) addtext(Provience,Yes,Male,Yes) tex excel append
	areg bmi incontrol age  $control1 if gender==0 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(incontrol  age $control1) bdec(3) addtext(Provience,Yes,Male,No) tex excel append
	areg bmi intrenal external age  $control1 if gender==1 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(intrenal external age $control1) bdec(3) addtext(Provience,Yes,Male,Yes) tex excel append
	areg bmi intrenal external age  $control1 if gender==0 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(intrenal external age $control1) bdec(3) addtext(Provience,Yes,Male,No) tex excel append
	areg overweight incontrol age  $control1 if gender==1 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(incontrol  age $control1) bdec(3) addtext(Provience,Yes,Male,Yes) tex excel append
	areg overweight incontrol age  $control1 if gender==0 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(incontrol  age $control1) bdec(3) addtext(Provience,Yes,Male,No) tex excel append
	areg overweight intrenal external age  $control1 if gender==1 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(intrenal external age $control1) bdec(3) addtext(Provience,Yes,Male,Yes) tex excel append
	areg overweight intrenal external age  $control1 if gender==0 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(intrenal external age $control1) bdec(3) addtext(Provience,Yes,Male,No) tex excel append
	areg obese incontrol age  $control1 if gender==1 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(incontrol  age $control1) bdec(3) addtext(Provience,Yes,Male,Yes) tex excel append
	areg obese incontrol age  $control1 if gender==0 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(incontrol  age $control1) bdec(3) addtext(Provience,Yes,Male,No) tex excel append
	areg obese intrenal external age  $control1 if gender==1 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(intrenal external age $control1) bdec(3) addtext(Provience,Yes,Male,Yes) tex excel append
	areg obese intrenal external age  $control1 if gender==0 ,absorb(provcd)
	outreg2 using "$output/self_bmi_gender",adjr2 keep(intrenal external age $control1) bdec(3) addtext(Provience,Yes,Male,No) tex excel append
	
*非参数绘图
*Figure
	twoway lowess weight incontrol , bwidth(10) xtitle("locus of control")  ytitle("Weight") title("体重")
	graph save "$output/weight.gph",replace 
	graph export "$output/weight.png",replace 

	twoway lowess bmi incontrol , bwidth(10) xtitle("locus of control")  ytitle("Body Mass Index ")  title("BMI")
	graph save "$output/bmi.gph",replace 
	graph export "$output/bmi.png",replace 
	
	twoway lowess overweight incontrol , bwidth(10) xtitle("locus of control")  ytitle("Overweight") title("超重")
	graph save "$output/overweight.gph",replace  
	graph export "$output/overweight.png",replace 
	
	twoway lowess obese incontrol , bwidth(10) xtitle("locus of control")  ytitle("Obese")  title("肥胖")
	graph save "$output/obese.gph",replace 
	graph export "$output/obese.png",replace 
	
	graph combine "$output/weight.gph" "$output/bmi.gph" "$output/overweight.gph" "$output/obese.gph"
	graph export "$output/lowess.png",replace 


*对行为的影响
	areg smoking incontrol age  $control  ,absorb(provcd)
	outreg2 using "$output/jz",adjr2 keep(incontrol age $control) bdec(3) addtext(Provience,Yes) tex excel replace
	areg smoking intrenal external age  $control  ,absorb(provcd)
	outreg2 using "$output/jz",adjr2 keep(intrenal external age $control) bdec(3) addtext(Provience,Yes) tex excel append
	areg exercise incontrol age  $control  ,absorb(provcd)
	outreg2 using "$output/jz",adjr2 keep(incontrol age $control) bdec(3) addtext(Provience,Yes) tex excel append
	areg exercise intrenal external age  $control  ,absorb(provcd)
	outreg2 using "$output/jz",adjr2 keep(intrenal external age $control) bdec(3) addtext(Provience,Yes) tex excel append
	areg health_eating incontrol age  $control  ,absorb(provcd)
	outreg2 using "$output/jz",adjr2 keep(incontrol age $control) bdec(3) addtext(Provience,Yes) tex excel append
	areg health_eating intrenal external age  $control  ,absorb(provcd)
	outreg2 using "$output/jz",adjr2 keep(intrenal external age $control) bdec(3) addtext(Provience,Yes) tex excel append
	







