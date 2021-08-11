*** Metrics
*** Table 1.1
*** goal: make table of health outcomes and characteristics by insurance status ***

* by Georg Graetz, August 6, 2013
* modified lightly by Gabriel Kreindler, June 13, 2014
* modified lightly by Jon Petkun, January 2, 2015
* modified lightly by Ryan Hill, Jan 31, 2020
* modified lightly by Ashar Farooq, March 2, 2021


pause on
clear all
clear
set more off
cap log close

* right directory change
cd "/Users/asharfarooq/Downloads/Real Data Empirics"

cap log using NHIS2009_hicomparePARTB2CFORREAL2.log, text replace

use NHIS2009_clean, clear

* select non-missings
	// selecting the different criterias for producing a table for wives and husbands and insurance status, among other group characteristics
	
	keep if marradult==1 & perweight!=0 
		by serial: egen hi_hsb = mean(hi_hsb1)
			keep if hi_hsb!=. & hi!=.
		by serial: egen female = total(fml)
			keep if female==1
			drop female
	
* Josh's sample selection criteria	
	gen angrist = ( age>=26 & age<=59 & marradult==1 & adltempl>=1)
		keep if angrist==1
	// drop single-person HHs
	by serial: gen n = _N
		keep if n>1
		
// keep only males 
keep if fml == 0

// creating a variable for college graduate or not
gen college_graduate = (yedu >= 16)

// creating a variable for employed college graduate or not
gen emplGraduate = (college_graduate * empl)

// doing a t test based on health for group who are employed graduates and one that does not
ttest hlth, by (emplGraduate)

// doing a t test based on employed graduates for group who has some health
ttest emplGraduate, by (hi)

cap log close

translate NHIS2009_hicomparePARTB2CFORREAL2.log NHIS2009_hicomparePARTB2CFORREAL2.pdf


* select non-missings
	// selecting the different criterias for producing a table for wives and husbands and insurance status, among other group characteristics
	
	keep if marradult==1 & perweight!=0 
		by serial: egen hi_hsb = mean(hi_hsb1)
			keep if hi_hsb!=. & hi!=.
		by serial: egen female = total(fml)
			keep if female==1
			drop female
	
* Josh's sample selection criteria	
	gen angrist = ( age>=26 & age<=59 & marradult==1 & adltempl>=1 )
		keep if angrist==1
	// drop single-person HHs
	by serial: gen n = _N
		keep if n>1


* Prepare matrix to store results in order to produce a table that can be exported to an Excel file
	matrix results = J(15,6,.)
	matrix rownames results = "Health index" "se" "Nonwhite" "se" "Age" "se" "Education" "se" "Family Size" "se" "Employed" "se" "Family income" "se" "Sample size"
	matrix colnames results = "Husbands: Some HI" "Husbands: No HI" "Husbands: Difference" "Wives: Some HI" "Wives: No HI" "Wives: Difference" 

	matrix list results,format(%8.4f)
	
	local col = 1
	local row1 = 1
	local row2 = 2
	

 * Health status(based on the 1-5 health scale for instance) by insurance coverage(Some HI versus No HI) and sex(helpful for getting information on husbands sample)
 
	forval fem = 0/1 {
	qui sum hlth if hi==1 & fml==`fem' [ aw=perweight ]
		mat results[`row1',`col'] = r(mean)
		mat results[`row2',`col'] = r(sd)
		local ++col
		
	qui sum hlth if hi==0 & fml==`fem' [ aw=perweight ]
		mat results[`row1',`col'] = r(mean)
		mat results[`row2',`col'] = r(sd)
		local ++col

	reg hlth hi if fml==`fem' [ aw=perweight ], robust
		mat results[`row1',`col'] = _b[hi]
		mat results[`row2',`col'] = _se[hi]
		local ++col
	}
		
		local row1 = `row1' + 2
		local row2 = `row2' + 2

* Other characteristics(health was already done) by insurance and sex(Some HI versus No HI    and     husbands versus wives)	

	foreach var in nwhite age yedu famsize empl inc {
		
		local col = 1
		forval fem = 0/1 {
		
		* means and SDs
			qui sum `var' if hi==1 & fml==`fem' [ aw=perweight ]
				mat results[`row1',`col'] = r(mean)
				local ++col
			qui sum `var' if hi==0 & fml==`fem' [ aw=perweight ]
				mat results[`row1',`col'] = r(mean)
				local ++col
				
		* mean comparisons 
			reg `var' hi if fml==`fem' [ w=perweight ], robust
				mat results[`row1',`col'] = _b[hi]
				mat results[`row2',`col'] = _se[hi]
				local ++col
						
		}		
		local row1 = `row1' + 2
		local row2 = `row2' + 2
	}
		
	* Sample sizes
	tab hi if fml == 0 [aw=perweight], matcell(x)
	mat list x
	
	mat results[`row1',2] = x[1,1]
	mat results[`row1',1] = x[2,1]
	
	tab hi if fml == 1 [aw=perweight], matcell(y)
	mat list y
	
	mat results[`row1',5] = y[1,1]
	mat results[`row1',4] = y[2,1]

* List results
matrix list results, format(%8.2f)		
		
	
* Output results	
putexcel set PARTB2BLL, replace
putexcel A1 = matrix(results), names nformat(number_d2)

translate NHIS2009_hicomparePARTB2CREAL.log NHIS2009_hicomparePARTB2CREAL.pdf

cap log close
