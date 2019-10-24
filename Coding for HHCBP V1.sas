/* Look at the difference in qualty performance of the home health agencies in the APM states using VBP 
compared to states that are not in the VBP states. DiD analysis now that the program has had a full year 
of data to review from the PUF file */

libname puf '**********************h Work\puffiles';

/* want to bring in my small sorting macro*/
%include '*************************** macros\sort.sas';

%Macro import(d1, type,  d2);

proc import datafile = "****************arch Work\puffiles\&d1"
dbms = &type out = &d2 (rename = (Provider_ID = CMS_Certification_Number__CCN_)) replace;
run;
%mend;

%import(puf2014.xlsx ,xlsx,  puf2014)
%import(puf2015 ,xlsx,  puf2015)
%import(puf2016.xlsx ,xlsx,  puf2016)

data puf2017;
	set puf.puf2017;
	drop  Percent_of_Beneficiaries_with_At
 Percent_of_Beneficiaries_with_Al
 Percent_of_Beneficiaries_with_As 
 Percent_of_Beneficiaries_with_Ca 
 Percent_of_Beneficiaries_with_CH 
Percent_of_Beneficiaries_with_C1 
 Percent_of_Beneficiaries_with_CO 
 Percent_of_Beneficiaries_with_De 
 Percent_of_Beneficiaries_with_Di 
Percent_of_Beneficiaries_with_Hy 
Percent_of_Beneficiaries_with_H1 
 Percent_of_Beneficiaries_with_IH 
 Percent_of_Beneficiaries_with_Os 
 Percent_of_Beneficiaries_with_RA 
Percent_of_Beneficiaries_with_Sc 
Percent_of_Beneficiaries_with_St;
	CMS_Certification_Number__CCN_ = input(provider_id, 6.);

	run;
options mlogic;

%import(emergency2014.csv, csv , emergency2014)
%import(emergency2015.csv, csv, emergency2015)
%import(other2014.csv,csv, other2014)
%import(other2015.csv,csv, other2015)
%import(other2016.csv,csv, hhc_2016)
%import(other2017.csv,csv, hhc_2017)
/*Now I need to sort the 14 and 15 data because they are measured at different times*/

%sort(emergency2014, CMS_Certification_Number__CCN_)
%sort(other2014, CMS_Certification_Number__CCN_)
%sort(emergency2015, CMS_Certification_Number__CCN_)
%sort(other2015, CMS_Certification_Number__CCN_)

/*Merge them together*/

data hhc_2015;
merge other2015 (in = a) emergency2015 (in = b);
by CMS_Certification_Number__CCN_;
if a;
if b;
run;

data hhc_2014;
merge other2014 (in = a) emergency2014 (in = b);
by CMS_Certification_Number__CCN_;
if a; if b;
run;

%macro merge(hccpuf, first, second);

data &hccpuf;
	merge &first (in = a) &second (in = b);
	by CMS_Certification_Number__CCN_;
	if a;
	if b;
run;
%mend;

%sort(hhc_2014, CMS_Certification_Number__CCN_)
%sort(hhc_2015, CMS_Certification_Number__CCN_)
%sort(hhc_2016, CMS_Certification_Number__CCN_)
%sort(hhc_2017, CMS_Certification_Number__CCN_)


%sort(puf2014, CMS_Certification_Number__CCN_)
%sort(puf2015, CMS_Certification_Number__CCN_)
%sort(puf2016, CMS_Certification_Number__CCN_)
%sort(puf2017, CMS_Certification_Number__CCN_)

%merge(hccpuf_14, hhc_2014 , puf2014)
%merge(hccpuf_15, hhc_2015 , puf2015)
%merge(hccpuf_16, hhc_2016 , puf2016)
%merge(hccpuf_17, hhc_2017 , puf2017)
/*Stack the data sets for myself to have one database*/
data study_set;
	set hccpuf_14
	hccpuf_15
	hccpuf_16
	hccpuf_17;
	drop  Percent_of_Beneficiaries_with_At
 Percent_of_Beneficiaries_with_Al
 Percent_of_Beneficiaries_with_As 
 Percent_of_Beneficiaries_with_Ca 
 Percent_of_Beneficiaries_with_CH 
Percent_of_Beneficiaries_with_C1 
 Percent_of_Beneficiaries_with_CO 
 Percent_of_Beneficiaries_with_De 
 Percent_of_Beneficiaries_with_Di 
Percent_of_Beneficiaries_with_Hy 
Percent_of_Beneficiaries_with_H1 
 Percent_of_Beneficiaries_with_IH 
 Percent_of_Beneficiaries_with_Os 
 Percent_of_Beneficiaries_with_RA 
Percent_of_Beneficiaries_with_Sc 
Percent_of_Beneficiaries_with_St ;

if Type_of_ownership = 'Combination GOVT & Vol' or 
	Type_of_ownership = 'Government - Combinati' or
	Type_of_ownership = 'Government - State/ Co' or
	Type_of_ownership = 'Local' or
	 Type_of_ownership = 'State/County' or
	Type_of_ownership = 'Government - Local' then gov = 1;
		else gov = 0;


if Type_of_ownership = 'Proprietary' then fp = 1;
	else fp = 0;

	if fp ne 1 and gov ne 1 then nfp = 1;
		else nfp = 0;

	   /*ID my states that are part of the program*/

hhvbp = 0;
if (State = "AZ" or State =  "FL"  or State =  "IA" or State =  "MD" 
or State =   "MA" or State =  "NE" or State =  "NC" or State =  "TN" or  State =  "WA") then hhvbp =1 ;


/*Must build my index scores of care*/
array numeric (16) timely_manner taught_drugs check_falling check_depression  flu_shot pn_shot diab_footcare_talk 
	      walk bed bath drugs_mouth hospital emergency
	lesspain_move breathing wounds_heal;
	array id (16) timely_manner_id taught_drugs_id check_falling_id check_depression_id  flu_shot_id pn_shot_id diab_footcare_talk_id 
	 walk_id bed_id bath_id drugs_mouth_id hospital_id emergency_id
	lesspain_move_id breathing_id wounds_heal_id;
		do i = 1 to 22;

			 if numeric(i) ge 1 then id(i) = 1;
			 	else id(i) = 0;

			end;

	/* Start generating my composite score*/
		/* Daily Score*/
			daily_sum = walk+bed+bath;
			daily_div =walk_id + bed_id + bath_id;
			if daily_div = 0 then daily_div = .;
			daily_score = daily_sum/daily_div;

		/*Managing Pain and Treating Symptoms*/
			pain_sum = lesspain_move + breathing;
			pain_div = lesspain_move_id + breathing_id;
			if pain_div = 0 then pain_div = .;
			pain_score = pain_sum/pain_div;


		/*Harm Score*/
			harm_sum = timely_manner + taught_drugs + check_falling + check_depression + flu_shot + pn_shot +
			diab_footcare_talk + drugs_mouth;
			harm_div = timely_manner_id + taught_drugs_id + check_falling_id + check_depression_id + flu_shot_id + pn_shot_id +
			diab_footcare_talk_id + drugs_mouth_id;
			if harm_div = 0 then harm_div = .;
			harm_score = harm_sum/harm_div;

run;





proc freq data = study_set;
table Type_of_Ownership nfp fp gov;
title 'Check the types of agencies';
run;
