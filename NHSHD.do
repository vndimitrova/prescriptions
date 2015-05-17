/* To download the prescribing data, go through the BSA Information Services Portal at https://apps.nhsbsa.nhs.uk/infosystems/welcome 
and sign in as a guest. 

Select the option "+Data" and then choose "Prescribing Data" > " "Detailed Prescribing Information"

Select the report criteria as "Practices Prescribing Information - Nationally" / Period  e.g. February 2015 and then "All Chapters" 
The all chapters prescribing data for February 2015 is saved as "feb2015.csv".

To understand the BNF presentaion code go to "+Data", then select "Drug Data" and then "BNF Code Information" - saved in the repository as "bnf.csv"

To merge with the patient list size of the general practices choose "Demographic Data" - saved in the repository as "patient_list_size.csv" 

The merging with post code data is through using the EPRACCUR data from the HSCIC at http://systems.hscic.gov.uk/data/ods/datadownloads/gppractice 
Practice codes to post codes are saved as "postcode_practice.csv". The data documentation is uploaded as epraccur.pdf */


* ---------------------------------------------------------------------------- * 

* Preparing a file containing the practice codes and the postcodes and keeping a couple of other indicators about the GP practice:
insheet using postcode_practice.csv, clear
save postcode_practice.dta, replace

use postcode_practice.dta, clear
keep v1 v2 v10 v13 v26
rename v1 practicecode
rename v2 practicename
rename v10 postcode
rename v13 practicestatus
rename v26 pres_setting
save postcode_practice.dta, replace

* ---------------------------------------------------------------------------- * 

* Preparing a file containing the practice codes and patient list size:
insheet using patient_list_size.csv, clear
save patient_list_size.dta, replace

use patient_list_size.dta, clear
gen size = male75 + male6574 + male5564 + male4554 + male3544 + male2534 + male1524 + male514 + male04  ///
 + female75 + female6574 + female5564 + female4554 + female3544 + female2534 + female1524 + female514 + female04
gen size_female = male75 + male6574 + male5564 + male4554 + male3544 + male2534 + male1524 + male514 + male04
gen size_male = female75 + female6574 + female5564 + female4554 + female3544 + female2534 + female1524 + female514 + female04
keep practicecode size size_female size_male
save patient_list_size.dta, replace


* ---------------------------------------------------------------------------- * 

* Insheeting the prescribing data for February 2015:
insheet using feb2015.csv, clear
save feb2015.dta, replace

use feb2015.dta, clear

* Generating a shorter code to identify the BNF section (bnfshort) and the BNF subparagraph (bnfsub):
gen bnfshort = substr(bnfcode,1,4)
gen bnfsub = substr(bnfcode,1,7)

* Keeping only the section of antibacterial drugs (could be any other chapter)...
keep if bnfshort == "0501"
save antibacterial.dta, replace
outsheet using antibacterial.csv, comma

* ---------------------------------------------------------------------------- * 

use antibacterial.dta, clear

* Merge with the postcode data:
merge m:1 practicecode using postcode_practice.dta
* 650 were only in the master, as these are "unidentified doctors", 3,668 were not found in the master.
* Keeping only the merged observations:
keep if _merge == 3
drop _merge

* Summing up the quantities and values over the subparagaph for each practice:
collapse (sum) quantity items nic adqusage actualcost,  ///
by(practicecode bnfsub postcode regionalofficename regionalofficecode ///
pres_setting practicestatus practicename pconame pcocode areateamname areateamcode)

* Merging with the patient list size data:
merge m:1 practicecode using patient_list_size.dta
keep if _merge == 3
drop _merge

* Generating the total quantity by multiplying the number of items / packages with the number of pills:
gen total_quantity = items * quantity
* Generating a ratio of quantity prescribed over the patient list size:
gen weighted_quantity = total_quantity / size

* Keeping only one subparagraph e.g. 501013 which is "Broad-Spectrum Penicillins"
keep if bnfsub == "0501013"

save penicillins.dta, replace
outsheet using penicillins.csv, comma

