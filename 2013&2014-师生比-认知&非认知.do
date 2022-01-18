  
  clear all
  set more off
  set scrollbufsize 2048000
  capture log close
  set maxvar 32767

  global dtadir     "/Users/wangnan/Desktop/CEPS_Data_Writing/dta"
  global savedir    "/Users/wangnan/Desktop/CEPS_Data_Writing/save"
  global resultsdir "/Users/wangnan/Desktop/CEPS_Data_Writing/result"
  
/*-------
Step 1: 合并基线、追踪学生和最终家长数据
--------*/	

**合并基线学生、老师、家长、校长数据

  use "$dtadir/CEPS基线调查班级数据.dta",clear
  merge 1:m clsids using "$dtadir/CEPS基线调查学生数据.dta"
  drop _merge
  save "$dtadir/CEPS_Basic_teacher&student.dta",replace

  use "$dtadir/CEPS基线调查学校数据.dta",clear
  merge 1:m schids using "$dtadir/CEPS_Basic_teacher&student.dta"
  drop _merge
  save "$dtadir/CEPS_Basic_teacher&student&principal.dta",replace
  
  use "$dtadir/CEPS基线调查家长数据.dta",clear
  merge 1:1 ids using "$dtadir/CEPS_Basic_teacher&student&principal.dta"
  drop _merge
  save "$dtadir/CEPS_Basic_teacher&student&principal&parent.dta",replace

**合并追踪学生、老师、家长、校长数据

 use "$dtadir/CEPS_Trace_Teacher.dta",clear
  *bysort tchids: gen tea_num=_n
  *list tchids w2clsids schids ctyids tchids w2tchsubject w2tchhr w2tchc01    ///
  *w2tchc02 w2tchc03 w2tchc04 w2tchc05 w2tchc06 w2tchc07 w2tchc08 w2tchc09    ///
  *w2tchc10a if tchids==1491 
  *drop if tea_num==2 | tea_num==3      //编码重复出现的老师是同一人
  *drop tea_num
  tab tchids,m
  
  gen wsubject=w2tchsubject                 //生成数学、语文、英语等老师的转置编码
  label var wsubject "任课老师的科目 0=其他 1=数学 2=语文 3=英语"
  reshape wide tchids-w2tchc3105,i(w2clsids) j(wsubject)          //转置后有291名老师
  save "$dtadir/CEPS_Trace_Teacher_转置.dta",replace
 
  use "$dtadir/CEPS_Trace_Teacher_转置.dta",clear
  merge 1:m w2clsids using "$dtadir/CEPS_Trace_Student.dta"       //有10750名学生
  drop _merge                                //847名学生没有merge上
  save "$dtadir/CEPS_Trace_teacher&student.dta",replace

  use "$dtadir/CEPS_Trace_Principal.dta",clear
  merge 1:m schids using "$dtadir/CEPS_Trace_teacher&student.dta"
  drop _merge
  save "$dtadir/CEPS_Trace_teacher&student&principal.dta",replace
  
  use "$dtadir/CEPS_Trace_Parent.dta",clear
  merge 1:1 ids using "$dtadir/CEPS_Trace_teacher&student&principal.dta"
  drop _merge
  save "$dtadir/CEPS_Trace_teacher&student&principal&parent.dta",replace         

/*-------
Step 2: 处理基线变量
--------*/	  
  
  use "$dtadir/CEPS_Basic_teacher&student&principal&parent.dta",clear
  
***********计算师生比

   ***校长问卷里报告的师生比
   
   tab plc0107,m
   sum plc0107
   rename plc0107 tea_stu_pro 
   tab tea_stu_pro,m
   
   split tea_stu_pro, parse("：") gen(newvar_) 
   split tea_stu_pro if newvar_2=="", parse(":") gen(newvar) 
   *br newvar_1 newvar_2 newvar1 newvar2
   
   gen newvar1_1=newvar1
   replace newvar1_1=newvar_1 if regexm(newvar_1,":")!=1 
   
   gen newvar2_2=newvar2
   replace newvar2_2=newvar_2 if newvar_2!=""
   
   destring newvar2_2 newvar1_1,replace
   gen tea_stu_pro_2=newvar2_2/newvar1_1
   tab tea_stu_pro_2,m
   label var tea_stu_pro_2 "学校师生比"
   
   drop newvar_1 newvar_2 newvar1 newvar2 
   
   gen tea_stu_pro_2_1=newvar1_1/newvar2_2 if tea_stu_pro_2==4 | tea_stu_pro_2==8 | tea_stu_pro_2==9.8 | tea_stu_pro_2==10.4 | tea_stu_pro_2==11 | tea_stu_pro_2==11.3 |tea_stu_pro_2==12.5 | tea_stu_pro_2==13 | tea_stu_pro_2==13.8 | tea_stu_pro_2==14 | tea_stu_pro_2==15 | tea_stu_pro_2==16 | tea_stu_pro_2==19.6  
   
   //第一步师生比数值过大的，将生师比反过来，查看数据
   ***根据教师数量、学生数量计算的教师数量
   
   tab plc0101a,m                                   //各学校教师总数
   rename plc0101a pri_teanum_2013
   label var pri_teanum_2013 "学校教师人数_2013"
   
   gen stu_num_school_2013=plb0101b+plb0102b+plb0103b    //各学校学生总数
   tab stu_num_school_2013,m  
   label var stu_num_school_2013 "学校学生人数_2013"
   
   gen tea_stu_pro_1=pri_teanum_2013/stu_num_school_2013  //师生比
   tab tea_stu_pro_1
   label var tea_stu_pro_1 "学校师生比-自己计算"
   
   list newvar2_2 newvar1_1 tea_stu_pro_2 tea_stu_pro_2_1 tea_stu_pro_1 if tea_stu_pro_2==4 |   tea_stu_pro_2==8 | tea_stu_pro_2==9.8 | tea_stu_pro_2==10.4 | tea_stu_pro_2==11 | tea_stu_pro_2==11.3 | tea_stu_pro_2==12.5 | tea_stu_pro_2==13 | tea_stu_pro_2==13.8 | tea_stu_pro_2==14 | tea_stu_pro_2==15 | tea_stu_pro_2==16 | tea_stu_pro_2==19.6 
   
   tab tea_stu_pro_2,m
   
   list schids newvar2_2 newvar1_1 tea_stu_pro_2 tea_stu_pro_2_1 tea_stu_pro_1 if tea_stu_pro_2==9.80 
   order tea_stu_pro, after(tea_stu_pro_1)
   list tea_stu_pro newvar2_2 newvar1_1 tea_stu_pro_2 tea_stu_pro_2_1 tea_stu_pro_1 
   list tea_stu_pro newvar2_2 newvar1_1 tea_stu_pro_2 tea_stu_pro_2_1 tea_stu_pro_1 if tea_stu_pro_2==10.40
      
  ***将校长报告的师生比重数值较大的进行修改，与自己算出的师生比进行核对
   order tea_stu_pro_2,after(schids)
   
   replace tea_stu_pro_2 = 0.13 if tea_stu_pro_2 == 8
   replace tea_stu_pro_2 = 0.12 if tea_stu_pro_2 == 11
   replace tea_stu_pro_2 = 0.29 if tea_stu_pro_2 == 4
   replace tea_stu_pro_2 = 0.08 if tea_stu_pro_2 == 12.5
   replace tea_stu_pro_2 = 0.10 if tea_stu_pro_2 == 13
   replace tea_stu_pro_2 = 0.13 if tea_stu_pro_2 == 14
   replace tea_stu_pro_2 = 0.06 if tea_stu_pro_2 == 16
   replace tea_stu_pro_2 = 0.07 if tea_stu_pro_2 == 15
   
   replace tea_stu_pro_2 = 0.09 if schids == 10           // tea_stu_pro_2 == 9.80 
   replace tea_stu_pro_2 = 0.10 if schids == 8            // tea_stu_pro_2 == 10.40
   replace tea_stu_pro_2 = 0.09 if schids == 7            // tea_stu_pro_2 == 11.30
   replace tea_stu_pro_2 = 0.07 if schids == 80           // tea_stu_pro_2 == 13.80
   replace tea_stu_pro_2 = 0.05 if schids == 103          // tea_stu_pro_2 == 19.60
  
  ***将师生比的空缺值，用自己计算的进行补充
   format tea_stu_pro_2 %9.2f
   format tea_stu_pro_1 %9.2f
   
   tab tea_stu_pro,m
   tab tea_stu_pro_2,m
   
   list schids tea_stu_pro_2 tea_stu_pro pri_teanum_2013 stu_num_school_2013       tea_stu_pro_1 if tea_stu_pro_2==.
   
   replace tea_stu_pro_2 = 0.09 if schids == 9
   replace tea_stu_pro_2 = 0.09 if schids == 11
   replace tea_stu_pro_2 = 0.12 if schids == 16
   replace tea_stu_pro_2 = 0.14 if schids == 30
   replace tea_stu_pro_2 = 0.21 if schids == 38
   replace tea_stu_pro_2 = 0.08 if schids == 77
   replace tea_stu_pro_2 = 0.13 if schids == 89
   replace tea_stu_pro_2 = 0.11 if schids == 91
   replace tea_stu_pro_2 = 0.08 if schids == 93
   replace tea_stu_pro_2 = 0.06 if schids == 105
   
   // 补充完成后，还有5个空缺值，无法补充
   /*
     +---------------------------------------------------------------+
     | schids   tea_st~2   tea_st~o   pri_nu~l   stu_nu~l   tea_~o_1 |
     |---------------------------------------------------------------|
 20. |     20          .                   114          .          . |
 36. |     36          .                    32          .          . |
 40. |     40          .                    20          .          . |
 53. |     53          .                     .       1953          . |
 96. |     96          .                     .          .          . |
     +---------------------------------------------------------------+
   */
   drop newvar1_1 newvar2_2 tea_stu_pro_2_1
   rename tea_stu_pro_2 tea_stu_pro_2013
   
  ***2012-2013学年离职、退休教师人数
   tab plc0104,m        
   
  ***三科老师的受教育水平
   tab chnb04,m    //语文老师受教育水平
   tab chnb07,m    //语文老师受教龄
   rename chnb04 chn_edu_level_2013
     label var chn_edu_level_2013 "语文老师受教育水平_2013"
   rename chnb07 chn_exp_age_2013
     label var chn_exp_age_2013 "语文老师教龄_2013"
	  
   tab matb04,m    //数学老师受教育水平
   tab matb07,m    //数学老师受教龄
   rename matb04 mat_edu_level_2013
     label var mat_edu_level_2013 "数学老师受教育水平_2013" 
   rename matb07 mat_exp_age_2013
     label var mat_exp_age_2013 "数学老师教龄_2013"
   
   tab engb04,m    //英语老师受教育水平
   tab engb07,m    //英语老师受教龄
   rename engb04 eng_edu_level_2013
     label var eng_edu_level_2013 "英语老师受教育水平_2013" 
   rename engb07 eng_exp_age_2013
     label var eng_exp_age_2013 "英语老师教龄_2013"
   
   ***班级规模
   bysort clsids: gen stu_num_class_2013=_N
     label var stu_num_class_2013 "班级规模_2013"
     tab stu_num_class_2013,m
   
   ***班主任教授的科目
   tab hra01,m     //班主任教授的是哪个科目
   
***********认知能力得分
   rename cog3pl cog3pl_2013
   
   ***学生标准化成绩（语文）
   egen std_chn_2013_grade7=std(stdchn) if grade9==0
   egen std_chn_2013_grade9=std(stdchn) if grade9==1
     
	 gen std_chn_2013=.
	 replace std_chn_2013=std_chn_2013_grade7 if grade9==0
	 replace std_chn_2013=std_chn_2013_grade9 if grade9==1
	 tab std_chn_2013,m
	   label var std_chn_2013 "标准化语文成绩_2014"
   
   ***学生标准化成绩（数学）
   egen std_mat_2013_grade7=std(stdmat) if grade9==0
   egen std_mat_2013_grade9=std(stdmat) if grade9==1
     
	 gen std_mat_2013=.
	 replace std_mat_2013=std_mat_2013_grade7 if grade9==0
	 replace std_mat_2013=std_mat_2013_grade9 if grade9==1
	 tab std_mat_2013,m
	   label var std_mat_2013 "标准化数学成绩_2014"
   
   ***学生标准化成绩（英语）
   egen std_eng_2013_grade7=std(stdmat) if grade9==0
   egen std_eng_2013_grade9=std(stdmat) if grade9==1
     
	 gen std_eng_2013=.
	 replace std_eng_2013=std_eng_2013_grade7 if grade9==0
	 replace std_eng_2013=std_eng_2013_grade9 if grade9==1
	 tab std_eng_2013,m
	   label var std_eng_2013 "标准化英语成绩_2014" 
 
**********非认知能力变量生成

     ***********责任心********************
	 factor a1201 a1202 a1203
	 estat kmo
     estat smc
	 predict cog1
     rename cog1 responsibility_2013
	 label var responsibility_2013 "责任心_2013"
	
	 egen std_responsibility_2013=std(responsibility_2013)
	 label var std_responsibility_2013 "责任心std_2013"
	 
	 ***********开放性********************
	 factor a1204 a1205 a1206 a1207
	 estat kmo
     estat smc
	 predict cog2
     rename cog2 open_mind_2013
	 label var open_mind_2013 "开放性_2013"
	 
	 egen std_open_mind_2013=std(open_mind_2013)
	 label var std_open_mind_2013 "开放性std_2013"
	
	 ***********神经质*********************
	 gen emotion_1=a1801
	 replace emotion_1=5 if a1801==1
	 replace emotion_1=4 if a1801==2
	 replace emotion_1=2 if a1801==4
	 replace emotion_1=1 if a1801==5
	 ta emotion_1,mi
					 		 
	 gen emotion_2=a1802
	 replace emotion_2=5 if a1802==1
	 replace emotion_2=4 if a1802==2
	 replace emotion_2=2 if a1802==4
	 replace emotion_2=1 if a1802==5
	 ta emotion_2,mi
					 			 					 
	 gen emotion_3=a1803
	 replace emotion_3=5 if a1803==1
	 replace emotion_3=4 if a1803==2
	 replace emotion_3=2 if a1803==4
	 replace emotion_3=1 if a1803==5
	 ta emotion_3,mi
			 
	 gen emotion_4=a1804
	 replace emotion_4=5 if a1804==1
	 replace emotion_4=4 if a1804==2
	 replace emotion_4=2 if a1804==4
	 replace emotion_4=1 if a1804==5
	 ta emotion_4,mi
					 
	 gen emotion_5=a1805
	 replace emotion_5=5 if a1805==1
	 replace emotion_5=4 if a1805==2
	 replace emotion_5=2 if a1805==4
	 replace emotion_5=1 if a1805==5
	 ta emotion_5,mi	
					 
     factor  emotion_1 emotion_2 emotion_3 emotion_4 emotion_5

	 estat kmo
     estat smc
     *screeplot
	 
	 predict cog3
     rename cog3 nervousness_2013
	 label var nervousness_2013 "神经质_2013"
	 
	 egen std_nervousness_2013=std(nervousness_2013)
	 label var std_nervousness_2013 "神经质std_2013"
	 
	 ***********外倾性*********************
	 factor c1707 c1709 c1710
	 estat kmo
     estat smc
	 predict cog4
     rename cog4 extroversion_2013
	 label var extroversion_2013 "外倾性_2013"
	 
	 egen std_extroversion_2013=std(extroversion_2013)
	 label var std_extroversion_2013 "外倾性std_2013"
	 
	 ***********宜人性*********************  标准化处理
	 tab c19,m
	 egen std_friend_2013=std(c19)   
	 label var std_friend_2013 "宜人性std_2013"
	 
	 *********计算总的非认知能力得分
	 
	 ***认知能力得分第一种算法
	 gen noncog_score_2013_1=responsibility_2013+open_mind_2013+nervousness_2013+extroversion_2013+c19
	 
	 sum noncog_score_2013_1
	 egen std_noncog_score_2013_1=std(noncog_score_2013_1)   
	 label var std_noncog_score_2013_1 "非认知能力std_2013_1"
	 
	 ***认知能力得分第二种算法
	 factor a1201 a1202 a1203 a1204 a1205 a1206 a1207 emotion_1 emotion_2 emotion_3 emotion_4 emotion_5 c1707 c1709 c1710 c19
	 
	 estat kmo
     estat smc
	 predict cog7
     rename cog7 noncog_score_2013_2
	 label var noncog_score_2013_2 "非认知能力_2013_2"
	 sum noncog_score_2013_2
	 
	 egen std_noncog_score_2013_2=std(noncog_score_2013_2)   
	 label var std_noncog_score_2013_2 "非认知能力std_2013_2"
	 
**********学生个人特征

     ***********性别********************	 
	 tab a01,m
	 rename a01 stu_male_2013
	   label var stu_male_2013 "学生性别_2013"
	   
	 ***********民族********************	 
	 tab a03,m
	 rename a03 stu_ethnic_2013
	   label var stu_ethnic_2013 "学生民族_2013"
	   
	 ***********户口类型********************	 
	 tab a06,m    
	 rename a06 stu_residence_2013
	   label var stu_residence_2013 "学生户口_2013"
	   
	 ***********学校的性质********************
	 tab pla01,m
	 rename pla01 sch_quality_2013
	   label var sch_quality_2013 "学校性质_2013"
	 
	 ***********学校的排名********************
	 tab pla04,m
	 rename pla04 sch_rank_2013
	   label var sch_rank_2013 "学校排名_2013"
	 
	 ***********学校所在地区的类型********************
	 tab pla23,m
	 rename pla23 sch_type_2013
	   label var sch_type_2013 "学校类型_2013"
	 
	 save "$dtadir/CEPS_Basic_teacher&student&principal&parent_clear.dta",replace

/*-------
Step 3: 处理追踪变量
--------*/	  
  
     use "$dtadir/CEPS_Trace_teacher&student&principal&parent.dta",clear
	 
	 ***********性别********************	 
	 *tab a01,m
	 
	 ***********民族********************	 
	 *tab a03,m
	 
	 ***********户口类型********************	 
	 tab w2a02,m
	 rename w2a02 stu_residence_2014
	   label var stu_residence_2014 "学生户口_2014"
	   
	 ***********学校的性质********************
	 tab w2pla01,m
	 rename w2pla01 sch_quality_2014
	   label var sch_quality_2014 "学校性质_2014"
	   
	 ***********学校的排名********************
	 tab w2pla03,m
	 rename w2pla03 sch_rank_2014
	   label var sch_rank_2014 "学校排名_2014"
	   
	 ***********学校所在地区的类型********************
	 tab w2pla19,m
	 rename w2pla19 sch_type_2014
	   label var sch_type_2014 "学校类型_2014"
	   
***********计算师生比

   ***校长问卷里报告的师生比	 
   tab w2plc0106,m
     gen tea_stu_pro_2014=1/w2plc0106
     label var tea_stu_pro_2014 "学校师生比_2014"
     tab tea_stu_pro_2014,m
 
     list ctyids schids clsids w2clsids if tea_stu_pro_2014==.
 
   //根据校长数据计算,补充空缺值
   gen stu_num_school_2014=w2plb0101b+w2plb0102b+w2plb0103b  
     label var stu_num_school_2014 "学校学生人数_2014"
 
     rename w2plc0101a pri_teanum_2014           
     label var pri_teanum_2014 "学校教师人数_2014"
     gen tea_stu_pro_1_2014=pri_teanum_2014/stu_num_school_2014
     label var tea_stu_pro_1_2014 "学校师生比_1"
  
     replace tea_stu_pro_2014=tea_stu_pro_1_2014 if tea_stu_pro_2014==.
     tab tea_stu_pro_2014,m
   
***********教师特征
   tab w2plf06,m     //老师的最高受教育水平
   tab w2plf11,m     //老师的从教年限
  
     ***其他教师
     tab w2tchc040,m     
     tab w2tchc080,m
       rename w2tchc040 other_edu_level_2014
       label var other_edu_level_2014 "其他老师受教育水平_2014"
     rename w2tchc080 other_exp_age_2014
       label var other_edu_level_2014 "其他老师教龄_2014"
     
	 ***数学教师
     tab w2tchc041,m
     tab w2tchc081,m
       rename w2tchc041 mat_edu_level_2014
       label var mat_edu_level_2014 "数学老师受教育水平_2014"
     rename w2tchc081 mat_exp_age_2014
       label var mat_exp_age_2014 "数学老师教龄_2014"
  
     ***语文教师
     tab w2tchc042,m
     tab w2tchc082,m
       rename w2tchc042 chn_edu_level_2014
       label var chn_edu_level_2014 "语文老师受教育水平_2014"
     rename w2tchc082 chn_exp_age_2014
       label var chn_exp_age_2014 "语文老师教龄_2014"
  
     ***英语教师
     tab w2tchc043,m
     tab w2tchc083,m
       rename w2tchc043 eng_edu_level_2014
       label var eng_edu_level_2014 "英语老师受教育水平_2014"
     rename w2tchc083 eng_exp_age_2014
       label var eng_exp_age_2014 "英语老师教龄_2014"
	
***********班级规模
     bysort clsids: gen stu_num_class_2014=_N
       label var stu_num_class_2014 "班级规模_2014"
       tab stu_num_class_2014,m
	 
***********认知能力得分
  tab w2cog3pl,m
  rename w2cog3pl w2cog3pl_2014
    
	***学生标准化成绩（语文）追踪7年级
	tab w2chn,m       
	  egen std_chn_2014=std(w2chn) 
	  label var std_chn_2014 "标准化语文成绩_2014"
       tab std_chn_2014,m
    
	***学生标准化成绩（数学）
	tab w2mat,m       
      egen std_mat_2014=std(w2mat) 
	  label var std_mat_2014 "标准化数学成绩_2014"
      tab std_mat_2014,m
    
	***学生标准化成绩（英语）
    tab w2eng,m       
      egen std_eng_2014=std(w2eng) 
	  label var std_eng_2014 "标准化英语成绩_2014"
      tab std_eng_2014,m

***********非认知能力得分

     ***********责任心********************
	 factor w2c2401 w2c2402 w2c2403
	 estat kmo
     estat smc
	 predict cog1
     rename cog1 responsibility_2014
	 label var responsibility_2014 "责任心_2014"
	 
	 egen std_responsibility_2014=std(responsibility_2014)
	 label var std_responsibility_2014 "责任心std_2014"
	 
	 ***********开放性********************    与基线题目不同
	 **w2d0302 w2d0303   题目相反
	 
	 factor w2d0305 w2d0307 w2d0308 w2d0309
	 estat kmo
     estat smc
	 predict cog2
     rename cog2 open_mind_2014
	 label var open_mind_2014 "开放性_2014"
	 
	 egen std_open_mind_2014=std(open_mind_2014)
	 label var std_open_mind_2014 "开放性std_2014"
	 
	 ***********神经质*********************
	 gen friends_quality_1_2=w2d1104 
	 replace friends_quality_1_2=3 if w2d1104==1
     replace friends_quality_1_2=1 if w2d1104==3
	 ta friends_quality_1_2,mi
					 
	 gen friends_quality_2_2=w2d1105 
	 replace friends_quality_2_2=3 if w2d1105==1
     replace friends_quality_2_2=1 if w2d1105==3
	 ta friends_quality_2_2,mi
	 
	 gen friends_quality_3_2=w2d1106 
	 replace friends_quality_3_2=3 if w2d1106==1
     replace friends_quality_3_2=1 if w2d1106==3
	 ta friends_quality_3_2,mi
	 
	 gen friends_quality_4_2=w2d1107 
	 replace friends_quality_4_2=3 if w2d1107==1
     replace friends_quality_4_2=1 if w2d1107==3
	 ta friends_quality_4_2,mi
	 
	 gen friends_quality_5_2=w2d1108 
	 replace friends_quality_5_2=3 if w2d1108==1
     replace friends_quality_5_2=1 if w2d1108==3
	 ta friends_quality_5_2,mi
	 
	 gen friends_quality_6_2=w2d1109
	 replace friends_quality_6_2=3 if w2d1109==1
     replace friends_quality_6_2=1 if w2d1109==3
	 ta friends_quality_6_2,mi
	 
	 gen friends_quality_7_2=w2d1110
	 replace friends_quality_7_2=3 if w2d1110==1
     replace friends_quality_7_2=1 if w2d1110==3
	 ta friends_quality_7_2,mi
	  
     factor friends_quality_1_2 friends_quality_2_2 friends_quality_3_2      ///
	 friends_quality_4_2 friends_quality_5_2 friends_quality_6_2 friends_quality_7_2,pcf
	 estat kmo
     estat smc
     *screeplot
	 
	 predict cog3
     rename cog3 nervousness_2014
	 label var nervousness_2014 "神经质_2014"
	 
     egen std_nervousness_2014=std(nervousness_2014)
	 label var std_nervousness_2014 "神经质std_2014"
	 
	 ***********外倾性*********************   缺1题
	 factor w2b0607 w2b0608
	 estat kmo
     estat smc
	 predict cog4
     rename cog4 extroversion_2014
	 label var extroversion_2014 "外倾性_2014"
	 
	 egen std_extroversion_2014=std(extroversion_2014)
	 label var std_extroversion_2014 "外倾性std_2014"
	 
	 ***********宜人性*********************  标准化处理
	 tab w2d09,m
	 egen std_friend_2014=std(w2d09)   
	 
	 label var std_friend_2014 "宜人性std_2014"
	 *********计算总的非认知能力得分
	 
	 ***第一种算法
	 gen noncog_score_2014_1=responsibility_2014+open_mind_2014+nervousness_2014+ ///
	 extroversion_2014+w2d09
	 sum noncog_score_2014_1
   	 label var noncog_score_2014_1 "非认知能力—2014-1"
	 
	 egen std_noncog_score_2014_1=std(noncog_score_2014_1)   
	 label var std_noncog_score_2014_1 "非认知能力std_2014_1"
	 
	 ***第二种算法
	 factor w2c2401 w2c2402 w2c2403 w2d0305 w2d0307 w2d0308 w2d0309 friends_quality_1_2 friends_quality_2_2 friends_quality_3_2 friends_quality_4_2 friends_quality_5_2 friends_quality_6_2 friends_quality_7_2 w2b0607 w2b0608 w2d09
	
	 estat kmo
     estat smc
	 predict cog6
     rename cog6 noncog_score_2014_2
	 label var noncog_score_2014_2 "非认知能力—2014_2"
	 sum noncog_score_2014_2
	 
	 egen std_noncog_score_2014_2=std(noncog_score_2014_2)   
	 label var std_noncog_score_2014_2 "非认知能力std_2014_2"	 
	 
	 save "$dtadir/CEPS_Trace_teacher&student&principal&parent_clear.dta",replace 

/*-------
Step 4: merge append 数据
--------*/	  
 
**合并基线、追踪学生数据  merge    宽数据    

  use "$dtadir/CEPS_Basic_teacher&student&principal&parent_clear.dta",clear
  merge 1:1 ids using "$dtadir/CEPS_Trace_teacher&student&principal&parent_clear.dta"
  drop _merge
  save "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_merge.dta",replace  
  // matched 上的有10279；not matched 基线9208 追踪471
  
**合并基线、追踪学生数据  append   长数据
  
  use "$dtadir/CEPS_Basic_teacher&student&principal&parent_clear.dta",clear 
  append using "$dtadir/CEPS_Trace_teacher&student&principal&parent_clear.dta"             
  save "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_append.dta",replace
  
/*-------
Step 5: 合并两期变量
--------*/	
  use "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_append.dta",clear
  **********************************合并两期数据*********************************
  ***学校特征
 
  *调查年份
  gen survey_year=0
  replace survey_year=1 if w2fall==0 | w2fall==1
  tab survey_year,m
  
  *师生比
  tab tea_stu_pro_2013,m
  tab tea_stu_pro_2014,m   
  sum tea_stu_pro_2013
  sum tea_stu_pro_2014
  
  gen tea_stu_pro_2013_2014=.n
  replace tea_stu_pro_2013_2014=tea_stu_pro_2013 if survey_year==0
  replace tea_stu_pro_2013_2014=tea_stu_pro_2014 if survey_year==1
  tab tea_stu_pro_2013_2014,m       //2013年有5个学校的生师比，无法计算
  sum tea_stu_pro_2013_2014
  
  egen tea_stu_pro_mean_tem=mean(tea_stu_pro_2013_2014) 
    label var tea_stu_pro_mean_tem "学校师生比均值"
  gen tea_stu_pro_2013_amean=tea_stu_pro_2013-tea_stu_pro_mean_tem
  gen tea_stu_pro_2014_amean=tea_stu_pro_2014-tea_stu_pro_mean_tem
    tab tea_stu_pro_2013_amean,m
	tab tea_stu_pro_2013_amean,m
   
  gen tea_stu_pro_2013_2014_amean=tea_stu_pro_2013_amean if survey_year==0
  replace tea_stu_pro_2013_2014_amean=tea_stu_pro_2014_amean if survey_year==1
    tab tea_stu_pro_2013_amean,m
    tab tea_stu_pro_2014_amean,m
	tab tea_stu_pro_2013_2014_amean,m
	
	ttest tea_stu_pro_2013_2014_amean,by(survey_year)
	
	sum tea_stu_pro_2013
	sum tea_stu_pro_2014
	
  *班级规模
  gen stu_num_class_2013_2014=.n
  replace stu_num_class_2013_2014=stu_num_class_2013 if survey_year==0
  replace stu_num_class_2013_2014=stu_num_class_2014 if survey_year==1
  tab stu_num_class_2013_2014,m
  
  *学校教师、学生人数
  tab stu_num_school_2013,m
  tab pri_teanum_2013,m
  
  tab stu_num_school_2014,m
  tab pri_teanum_2014,m
  
  //七、八、九年级退学、转出人数-2013
  gen stu_lost_2013=plb1301a+plb1301b+plb1302a+plb1302b+plb1303a+plb1303b
  tab stu_lost_2013,m
    label var stu_lost_2013 "学校流失学生人数_2013"
  list plb1301a plb1301b plb1302a plb1302b plb1303a plb1303b if stu_lost_2013==240
  
  //七、八、九年级退学、转出人数-2014
  	*list schids w2plb1001a w2plb1001b w2plb1002a w2plb1002b w2plb1003a w2plb1003b if stu_lost_2014==5988      //异常值处理
    
  gen stu_lost_2014_1=w2plb1001a+w2plb1001b+w2plb1002a+w2plb1002b+w2plb1003a+w2plb1003b
  tab stu_lost_2014_1,m
    
	list schids w2plb1001a w2plb1001b w2plb1002a w2plb1002b w2plb1003a w2plb1003b if stu_lost_2014==244
	
	replace  w2plb1001a=. if schids==81
	replace  w2plb1001b=. if schids==81
	replace  w2plb1002a=. if schids==81
	replace  w2plb1002b=. if schids==81
	replace  w2plb1003a=. if schids==81
	replace  w2plb1003b=. if schids==81
  
  gen stu_lost_2014=w2plb1001a+w2plb1001b+w2plb1002a+w2plb1002b+w2plb1003a+w2plb1003b
  tab stu_lost_2014,m
  label var stu_lost_2014 "学校流失学生人数_2014"
  
  //学校学生流失比例
  gen stu_lostratio_2013=stu_lost_2013/stu_num_school_2013
    label var stu_lostratio_2013 "学校学生流失比率_2013"
	tab stu_lostratio_2013,m
  gen stu_lostratio_2014=stu_lost_2014/stu_num_school_2014
    label var stu_lostratio_2014 "学校学生流失比率_2014"
    tab stu_lostratio_2014,m
  
  *br w2plb1001a w2plb1001b w2plb1002a w2plb1002b w2plb1003a w2plb1003b stu_lost_2014 stu_num_school_2014 stu_lostratio_2014 if stu_lostratio_2014>=12
   
  //学校学生流失比例2013&2014
  gen stu_lostratio_2013_2014=.n
    replace stu_lostratio_2013_2014=stu_lostratio_2013 if survey_year==0
    replace stu_lostratio_2013_2014=stu_lostratio_2014 if survey_year==1
	tab stu_lostratio_2013_2014,m
 
  *学生性别
  tab stu_male_2013,m
  tab stu_male_2013,nolabel 
  codebook stu_male_2013
  replace stu_male_2013=0 if stu_male_2013==2
  
  bysort ids: egen stu_male_2013_2014=mean(stu_male_2013)
  tab stu_male_2013_2014,m
  label var stu_male_2013_2014 "学生性别_2013_2014"
  *br ids stu_male_2013 stu_male_2013_2014
  *学生户口类型
  gen stu_residence_2013_2014=.
    replace stu_residence_2013_2014=stu_residence_2013 if survey_year==0
    replace stu_residence_2013_2014=stu_residence_2014 if survey_year==1
	label var stu_residence_2013_2014 "学生户口类型_2013_2014"
	tab stu_residence_2013_2014,m
	
    replace stu_residence_2013_2014=2 if stu_residence_2013_2014==2 | stu_residence_2013_2014==3 | stu_residence_2013_2014==4
    tab stu_residence_2013_2014,m
	label var stu_residence_2013_2014 "学生户口类型_2013_2014 1=农业户口 2=非农业户口"
  *学校性质
  gen stu_quality_2013_2014=.
    replace stu_quality_2013_2014=sch_quality_2013 if survey_year==0
    replace stu_quality_2013_2014=sch_quality_2014 if survey_year==1
    label var stu_quality_2013_2014 "学校性质_2013_2014"
	tab stu_quality_2013_2014,m
  
    replace stu_quality_2013_2014=0 if stu_quality_2013_2014==2 | stu_quality_2013_2014==3 | stu_quality_2013_2014==4
    tab stu_quality_2013_2014,m
	label var stu_quality_2013_2014 "学校性质_2013_2014 0=民办等学校 1=公立学校"
	
  *学校排名 
  gen stu_rank_2013_2014=.
    replace stu_rank_2013_2014=sch_rank_2013 if survey_year==0
    replace stu_rank_2013_2014=sch_rank_2014 if survey_year==1
    label var stu_rank_2013_2014 "学校排名_2013_2014"
    tab stu_rank_2013_2014,m
	
	replace stu_rank_2013_2014=0 if stu_rank_2013_2014==1 | stu_rank_2013_2014==2 | stu_rank_2013_2014==3
	replace stu_rank_2013_2014=1 if stu_rank_2013_2014==4 | stu_rank_2013_2014==5 
	tab stu_rank_2013_2014,m
	label var stu_rank_2013_2014 "学校排名_2013_2014 0=中间及以上 1=中间以上"
 
  *学校所在地区类型
  gen sch_type_2013_2014=.
    replace sch_type_2013_2014=sch_type_2013 if survey_year==0
    replace sch_type_2013_2014=sch_type_2014 if survey_year==1
	label var sch_type_2013_2014 "学校所在地区类型_2013_2014"
	tab sch_type_2013_2014,m
	
  replace sch_type_2013_2014=0 if sch_type_2013_2014==4 | sch_type_2013_2014==5
  replace sch_type_2013_2014=1 if sch_type_2013_2014==1 | sch_type_2013_2014==2 | sch_type_2013_2014==3
  label var sch_type_2013_2014 "学校所在地区类型_2013_2014 0=非县城学校 1=县城学校"
  tab sch_type_2013_2014,m
  
  /*
  gen sch_type_2013_2014_1=.
  replace sch_type_2013_2014_1=0 if sch_type_2013_2014==2 | sch_type_2013_2014==3 | sch_type_2013_2014==4 | sch_type_2013_2014==5
  replace sch_type_2013_2014_1=1 if sch_type_2013_2014==1
  tab sch_type_2013_2014_1,m
  label var sch_type_2013_2014 "学校所在地区类型_2013_2014 0=非县城中心城区学校 1=县城中心城区学校"
  */
  
  ***学生特征
  ***非认知能力（标准化得分）
  /*
  local var of varlist responsibility open_mind nervousness extroversion friend 
    gen std_`var'_2013_2014=.n
	replace std_`var'_2013_2014=std_`var'_2013 if survey_year==0
    replace std_`var'_2013_2014=std_`var'_2014 if survey_year==1
    tab std_`var'_2013_2014,m
  */
  *责任心
  gen std_responsibility_2013_2014=.n
  replace std_responsibility_2013_2014=std_responsibility_2013 if survey_year==0
  replace std_responsibility_2013_2014=std_responsibility_2014 if survey_year==1
  tab std_responsibility_2013_2014,m
  
  *开放性
  gen std_open_mind_2013_2014=.n
  replace std_open_mind_2013_2014=std_open_mind_2013 if survey_year==0
  replace std_open_mind_2013_2014=std_open_mind_2014 if survey_year==1
  tab std_open_mind_2013_2014,m
  
  *神经质
  gen std_nervousness_2013_2014=.n
  replace std_nervousness_2013_2014=std_nervousness_2013 if survey_year==0
  replace std_nervousness_2013_2014=std_nervousness_2014 if survey_year==1
  tab std_nervousness_2013_2014,m
  
  *外倾性
  gen std_extroversion_2013_2014=.n
  replace std_extroversion_2013_2014=std_extroversion_2013 if survey_year==0
  replace std_extroversion_2013_2014=std_extroversion_2014 if survey_year==1
  tab std_extroversion_2013_2014,m
  
  *宜人性
  gen std_friend_2013_2014=.n
  replace std_friend_2013_2014=std_friend_2013 if survey_year==0
  replace std_friend_2013_2014=std_friend_2014 if survey_year==1
  tab std_friend_2013_2014,m
  
  *非认知能力总分(第一种算法)
  gen std_noncog_score_2013_2014_1=.n
  replace std_noncog_score_2013_2014_1=std_noncog_score_2013_1 if survey_year==0
  replace std_noncog_score_2013_2014_1=std_noncog_score_2014_1 if survey_year==1
  list std_noncog_score_2013_2014_1
  
  *非认知能力总分(第二种算法)
  gen std_noncog_score_2013_2014_2=.n
  replace std_noncog_score_2013_2014_2=std_noncog_score_2013_2 if survey_year==0
  replace std_noncog_score_2013_2014_2=std_noncog_score_2014_2 if survey_year==1
  list std_noncog_score_2013_2014_2
  
  *认知能力
  gen std_cog_score_2013_2014=.n
  replace std_cog_score_2013_2014=cog3pl_2013   if survey_year==0
  replace std_cog_score_2013_2014=w2cog3pl_2014 if survey_year==1
  codebook std_cog_score_2013_2014
  sum std_cog_score_2013_2014
  
  *tab cog3pl_2013,m
  *tab w2cog3pl_2014,m
  ***学生成绩
  
  *数学成绩
  gen std_mat_2013_2014_2=.n
  replace std_mat_2013_2014_2=std_mat_2013 if survey_year==0
  replace std_mat_2013_2014_2=std_mat_2014 if survey_year==1
  tab std_mat_2013_2014_2,m      //1367个.
  sum std_mat_2013_2014_2
 
  *语文成绩
  gen std_chn_2013_2014_2=.n
  replace std_chn_2013_2014_2=std_chn_2013 if survey_year==0
  replace std_chn_2013_2014_2=std_chn_2014 if survey_year==1
  tab std_chn_2013_2014_2,m
  sum std_chn_2013_2014_2
  
  *英语成绩
  gen std_eng_2013_2014_2=.n
  replace std_eng_2013_2014_2=std_eng_2013 if survey_year==0
  replace std_eng_2013_2014_2=std_eng_2014 if survey_year==1
  tab std_eng_2013_2014_2,m
  sum std_eng_2013_2014_2
  
  ***教师特征
  *受教育水平
  //数学
  gen mat_edu_level_2013_2014=.n
  replace mat_edu_level_2013_2014=mat_edu_level_2013 if survey_year==0
  replace mat_edu_level_2013_2014=mat_edu_level_2014 if survey_year==1
  tab mat_edu_level_2013_2014,m
  
  //语文
  gen chn_edu_level_2013_2014=.n
  replace chn_edu_level_2013_2014=chn_edu_level_2013 if survey_year==0
  replace chn_edu_level_2013_2014=chn_edu_level_2014 if survey_year==1
  tab chn_edu_level_2013_2014,m
  
  //英语
  gen eng_edu_level_2013_2014=.n
  replace eng_edu_level_2013_2014=eng_edu_level_2013 if survey_year==0
  replace eng_edu_level_2013_2014=eng_edu_level_2014 if survey_year==1
  tab eng_edu_level_2013_2014,m
  
  *教龄
  //数学
  gen mat_exp_age_2013_2014=.n
  replace mat_exp_age_2013_2014=mat_exp_age_2013 if survey_year==0
  replace mat_exp_age_2013_2014=mat_exp_age_2014 if survey_year==1
  tab mat_exp_age_2013_2014,m
  
  //语文
  gen chn_exp_age_2013_2014=.n
  replace chn_exp_age_2013_2014=chn_exp_age_2013 if survey_year==0
  replace chn_exp_age_2013_2014=chn_exp_age_2014 if survey_year==1
  tab chn_exp_age_2013_2014,m
  
  //英语
  gen eng_exp_age_2013_2014=.n
  replace eng_exp_age_2013_2014=eng_exp_age_2013 if survey_year==0
  replace eng_exp_age_2013_2014=eng_exp_age_2014 if survey_year==1
  tab eng_exp_age_2013_2014,m
  
  ********************生成调查年与师生比的交互项
  
  gen pro_year=tea_stu_pro_2013_2014*survey_year
  tab pro_year,m
  
  save"$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_append_all.dta",replace        //生成两期数据共同变量后的数据
  
/*-------
Step 6: 保留两期均有的数据
--------*/	  
  
  //保留14年的数据，及成功追访的
  use"$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_append_all.dta",clear
  keep if survey_year==1
  keep if w2status==1
  *keep ids w2status survey_year
  save "$dtadir/CEPS_Traceteacher&student&principal&parent_clear_999.dta",replace   
  
  //保留13年的数据
  use "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_2.dta",clear
  keep if survey_year==0
  *drop w2clsids-w2d16
  save "$dtadir/CEPS_Basicteacher&student&principal&parent_clear_999.dta",replace 
  
  //将14年的数据与13年进行合并，从13年中保留14年成功追访的样本
  use "$dtadir/CEPS_Basicteacher&student&principal&parent_clear_999.dta",clear
  merge 1:1 ids using "$dtadir/CEPS_Traceteacher&student&principal&parent_clear_999.dta"
  keep if _merge==3
  tab w2status,m                          //成功追访9449
  *drop ids w2status survey_year
  save "$dtadir/CEPS_Basicteacher&student&principal&parent_clear_twoperiods_2013",replace 
  
  //保留14年有用的数据
  use "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_2.dta",clear
  keep if survey_year==1
  keep if w2status==1
  *drop ids-stprrel
  save "$dtadir/CEPS_Traceteacher&student&principal&parent_clear_twoperiods_2014",replace 
  
  //将13、14年均有的数据合并
  use "$dtadir/CEPS_Basicteacher&student&principal&parent_clear_twoperiods_2013",   clear
  append using "$dtadir/CEPS_Traceteacher&student&principal&parent_clear_twoperiods_2014"           
  save "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_twoperiods_both.dta",replace 
  
  *******************************仅保留2014年样本********************************
  use "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_append_all.dta",clear
  keep if survey_year==0
  save "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_2013_only.dta",replace
  
  use "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_append_all.dta",clear
  keep if survey_year==1
  save "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_2014_only.dta",replace
  ,
  *****************************************************************************
  
  **********************************回归分析***********************************
  *******************回归1：固定效应方法，使用两期数据（无论是否重复调查）*************
  ******回归1：认知能力(3pl认知得分、语文标准化成绩、数学标准化成绩、英语标准化成绩)
  oneway survey_year tea_stu_pro_2013_2014
  /*
  .   oneway survey_year tea_stu_pro_2013_2014

                        Analysis of Variance
    Source              SS         df      MS            F     Prob > F
------------------------------------------------------------------------
Between groups      3147.53686     91   34.5883172    275.97     0.0000
 Within groups      3699.90674  29520   .125335594
------------------------------------------------------------------------
    Total            6847.4436  29611   .231246618

Bartlett's test for equal variances:  chi2(20) = 439.3912  Prob>chi2 = 0.000

note: Bartlett's test performed on cells with positive variance:
      71 multiple-observation cells not used
   */

  use "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_append_all.dta",clear
  
  bysort survey_year: sum tea_stu_pro_2013_2014
  tab tea_stu_pro_2013_2014 if survey_year==0
  tab tea_stu_pro_2013_2014 if survey_year==1
  /*
  rename tea_stu_pro_2013_2014 tea_stu_pro_2013_2014_1
  winsor tea_stu_pro_2013_2014_1,gen(tea_stu_pro_2013_2014) p(0.1)
  */
  global y1 std_noncog_score_2013_2014_1 std_noncog_score_2013_2014_2 std_responsibility_2013_2014 std_open_mind_2013_2014 std_nervousness_2013_2014 std_extroversion_2013_2014 std_friend_2013_2014     //非认知能力
	
	
    eststo clear
    set matsize 600
    xtset ids survey_year
	
	eststo:xtreg std_cog_score_2013_2014 tea_stu_pro_2013_2014,fe 
	eststo:xtreg std_cog_score_2013_2014 tea_stu_pro_2013_2014 stu_num_class_2013_2014,fe 
	
	eststo:xtreg std_chn_2013_2014_2 tea_stu_pro_2013_2014,fe i(ids) 
	eststo:xtreg std_chn_2013_2014_2 tea_stu_pro_2013_2014 chn_edu_level_2013_2014,fe  
	eststo:xtreg std_chn_2013_2014_2 tea_stu_pro_2013_2014 chn_edu_level_2013_2014 stu_num_class_2013_2014,fe  
	eststo:xtreg std_chn_2013_2014_2 tea_stu_pro_2013_2014 chn_exp_age_2013_2014,fe  
	eststo:xtreg std_chn_2013_2014_2 tea_stu_pro_2013_2014 chn_exp_age_2013_2014 stu_num_class_2013_2014,fe 
	
	eststo:xtreg std_mat_2013_2014_2 tea_stu_pro_2013_2014,fe  
	eststo:xtreg std_mat_2013_2014_2 tea_stu_pro_2013_2014 mat_edu_level_2013_2014,fe 
	eststo:xtreg std_mat_2013_2014_2 tea_stu_pro_2013_2014 mat_edu_level_2013_2014 stu_num_class_2013_2014,fe  
	eststo:xtreg std_mat_2013_2014_2 tea_stu_pro_2013_2014 mat_exp_age_2013_2014,fe  
	eststo:xtreg std_mat_2013_2014_2 tea_stu_pro_2013_2014 mat_exp_age_2013_2014 stu_num_class_2013_2014,fe 
	
	eststo:xtreg std_eng_2013_2014_2 tea_stu_pro_2013_2014,fe  
	eststo:xtreg std_eng_2013_2014_2 tea_stu_pro_2013_2014 eng_edu_level_2013_2014,fe   
	eststo:xtreg std_eng_2013_2014_2 tea_stu_pro_2013_2014 eng_edu_level_2013_2014 stu_num_class_2013_2014,fe 
	eststo:xtreg std_eng_2013_2014_2 tea_stu_pro_2013_2014 eng_exp_age_2013_2014,fe  
	eststo:xtreg std_eng_2013_2014_2 tea_stu_pro_2013_2014 eng_exp_age_2013_2014 stu_num_class_2013_2014,fe 
	
    esttab using "${resultsdir}/method1-cog.csv",nolabel b(2) se(2) r2 star(* 0.10 ** 0.05 *** 0.01) obslast replace
    
   ******回归1：非认知能力
   eststo clear
   set matsize 600
   
	foreach var of varlist $y1 {
	eststo:xtreg `var' tea_stu_pro_2013_2014,fe i(ids)  
	eststo:xtreg `var' tea_stu_pro_2013_2014 stu_num_class_2013_2014,fe i(ids)  
    esttab using "${resultsdir}/method1-nocog.csv",nolabel b(2) se(2) r2 star(* 0.10 ** 0.05 *** 0.01) obslast replace
    }
	
	*******************回归2：固定效应方法，仅使用两期中重复出现的样本****************
    ****回归2：认知能力 (3pl认知得分、语文标准化成绩、数学标准化成绩、英语标准化成绩)***** 
    //长数据
    use "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_twoperiods_both.dta",clear
	
	global y1 std_noncog_score_2013_2014_1 std_noncog_score_2013_2014_2 std_responsibility_2013_2014 std_open_mind_2013_2014 std_nervousness_2013_2014 std_extroversion_2013_2014 std_friend_2013_2014        
	eststo clear
    set matsize 600
    xtset ids survey_year
	xtdes 
	*xtline tea_stu_pro_2013_2014
    xtile tea_stu_pro_2013_2014_3=tea_stu_pro_2013_2014, nq(3)
	
	eststo:xtreg std_cog_score_2013_2014 tea_stu_pro_2013_2014,fe  
	eststo:xtreg std_cog_score_2013_2014 tea_stu_pro_2013_2014 stu_num_class_2013_2014,fe 
	*eststo:xtreg std_cog_score_2013_2014 tea_stu_pro_2013_2014 sch_type_2013_2014,fe
	
	//xtreg std_cog_score_2013_2014 tea_stu_pro_2013_2014 i.year,fe i(ids) r  
	//r 表示聚类稳健标准误
	
	eststo:xtreg std_chn_2013_2014_2 tea_stu_pro_2013_2014,fe 
	eststo:xtreg std_chn_2013_2014_2 tea_stu_pro_2013_2014 stu_num_class_2013_2014,fe 
	*eststo:xtreg std_chn_2013_2014_2 tea_stu_pro_2013_2014 chn_edu_level_2013_2014 chn_exp_age_2013_2014 stu_male_2013_2014 stu_residence_2013_2014 stu_quality_2013_2014 stu_rank_2013_2014 sch_type_2013_2014,fe 
	
	eststo:xtreg std_mat_2013_2014_2 tea_stu_pro_2013_2014,fe 
	eststo:xtreg std_mat_2013_2014_2 tea_stu_pro_2013_2014 stu_num_class_2013_2014,fe 
	*eststo:xtreg std_mat_2013_2014_2 tea_stu_pro_2013_2014 mat_edu_level_2013_2014 mat_exp_age_2013_2014 stu_male_2013_2014 stu_residence_2013_2014 stu_quality_2013_2014 stu_rank_2013_2014 sch_type_2013_2014,fe 
	
	eststo:xtreg std_eng_2013_2014_2 tea_stu_pro_2013_2014,fe 
	eststo:xtreg std_eng_2013_2014_2 tea_stu_pro_2013_2014 stu_num_class_2013_2014,fe 
	*eststo:xtreg std_eng_2013_2014_2 tea_stu_pro_2013_2014 eng_edu_level_2013_2014 eng_exp_age_2013_2014 stu_male_2013_2014 stu_residence_2013_2014 stu_quality_2013_2014 stu_rank_2013_2014 sch_type_2013_2014,fe 
	
	esttab using "${resultsdir}/method2-cog.csv",nolabel b(2) se(2) r2 star(* 0.10 ** 0.05 *** 0.01) obslast replace
	
   ******回归2：非认知能力
   eststo clear
   set matsize 600
   
	foreach var of varlist $y1 {
	eststo:xtreg `var' tea_stu_pro_2013_2014,fe 
	eststo:xtreg `var' tea_stu_pro_2013_2014 stu_num_class_2013_2014,fe 
	*eststo:xtreg `var' tea_stu_pro_2013_2014 sch_type_2013_2014,fe  
	
    esttab using "${resultsdir}/method2-nocog.csv",nolabel b(2) se(2) r2 star(* 0.10 ** 0.05 *** 0.01) obslast replace
    }
    
	 *stu_male_2013_2014 stu_residence_2013_2014 stu_quality_2013_2014 stu_rank_2013_2014 sch_type_2013_2014
	**********************回归3：工具变量方法，仅使用2014-2015年数据*****************
    ******回归3：认知能力(3pl认知得分、语文标准化成绩、数学标准化成绩、英语标准化成绩)*****
   
	use "$dtadir/CEPS_Basic&Trace_teacher&student&principal&parent_clear_2014_only.dta",clear
	bysort survey_year: sum stu_lostratio_2013_2014
	tab stu_lostratio_2013_2014,m
	
	/*
	rename tea_stu_pro_2013_2014 tea_stu_pro_2013_2014_1
    winsor tea_stu_pro_2013_2014_1,gen(tea_stu_pro_2013_2014) h(200)
	
	rename stu_lostratio_2013_2014 stu_lostratio_2013_2014_1
    winsor stu_lostratio_2013_2014_1,gen(tea_stu_pro_2013_2014_2) h(200)
	rename tea_stu_pro_2013_2014_2 stu_lostratio_2013_2014
    */
  
	eststo clear
    set matsize 600
	
	global y1 std_noncog_score_2013_2014_1 std_noncog_score_2013_2014_2 std_responsibility_2013_2014 std_open_mind_2013_2014 std_nervousness_2013_2014 std_extroversion_2013_2014 std_friend_2013_2014
	
	tab stu_lostratio_2013_2014
	oneway stu_lostratio_2013_2014 survey_year 
	oneway survey_year stu_lostratio_2013_2014
    
	eststo:ivregress 2sls std_cog_score_2013_2014 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)
	
	eststo:ivregress 2sls std_cog_score_2013_2014 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)  stu_num_class_2013_2014
	
	*reg tea_stu_pro_2013_2014 stu_lostratio_2013_2014
	*reg std_cog_score_2013_2014 tea_stu_pro_2013_2014
	
	eststo:ivregress 2sls std_chn_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   
	eststo:ivregress 2sls std_chn_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   chn_edu_level_2013_2014 
	eststo:ivregress 2sls std_chn_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   chn_edu_level_2013_2014 stu_num_class_2013_2014 
	eststo:ivregress 2sls std_chn_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   chn_exp_age_2013_2014 
	eststo:ivregress 2sls std_chn_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   chn_exp_age_2013_2014 stu_num_class_2013_2014 
	
	eststo:ivregress 2sls std_mat_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   
	eststo:ivregress 2sls std_mat_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   mat_edu_level_2013_2014 
	eststo:ivregress 2sls std_mat_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   mat_edu_level_2013_2014 stu_num_class_2013_2014 
	eststo:ivregress 2sls std_mat_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   mat_exp_age_2013_2014 
	eststo:ivregress 2sls std_mat_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   mat_exp_age_2013_2014 stu_num_class_2013_2014 
	
	eststo:ivregress 2sls std_eng_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   
	eststo:ivregress 2sls std_eng_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   eng_edu_level_2013_2014 
	eststo:ivregress 2sls std_eng_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   eng_edu_level_2013_2014 stu_num_class_2013_2014 
	eststo:ivregress 2sls std_eng_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   eng_exp_age_2013_2014 
	eststo:ivregress 2sls std_eng_2013_2014_2 (tea_stu_pro_2013_2014=stu_lostratio_2013_2014)   eng_exp_age_2013_2014 stu_num_class_2013_2014 
	
	esttab using "${resultsdir}/method3-cog.csv",nolabel b(2) se(2) r2 star(* 0.10 ** 0.05 *** 0.01) obslast replace
	
	*回归3-非认知能力
    eststo clear
    set matsize 600
   
	foreach var of varlist $y1 {
	eststo:ivregress 2sls `var' (tea_stu_pro_2013_2014=stu_lostratio_2013_2014) 
	eststo:ivregress 2sls `var' (tea_stu_pro_2013_2014=stu_lostratio_2013_2014) stu_num_class_2013_2014 
	estat endogenous     
	estat firststage 
    esttab using "${resultsdir}/method3-nocog.csv",nolabel b(2) se(2) r2 star(* 0.10 ** 0.05 *** 0.01) obslast replace
    }
    

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	 
  
  
  
	
  
  
