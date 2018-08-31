clear
version 12
set more off
cap log close


global data  "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/data" // base de datos de personas
global data_procesada "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/data_procesada" //base de datos procesada de esta parte (crear carpeta)
global data_etiqueta_per "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/etiqueta_persona" //etiquetas de las personas
global data_etiqueta_geo "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/identif_geo" //data etiqueta geogrficas
global log "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/log" //carpeta para el log

cd "$log"
capture log close 
log using "replica_tabla_2.log", text replace 

cd "$data"

import delimited "personas.csv" , delimiter (";")

cd"$data_procesada"
save "personas.dta", replace
*NOTA SE GENERAN TABLAS DE EXCEL DE LA PREGUNTA 1 Y PREGUNTA 3


//----------------PREGUNTA 1------------------------
use "personas.dta"
*código de limpieza
gen reg_new = 2 if region == 1
replace reg_new = 3 if region == 2
replace reg_new = 4 if region == 3
replace reg_new = 5 if region == 4
replace reg_new = 6 if region == 5
replace reg_new = 8 if region == 6
replace reg_new = 9 if region == 7
replace reg_new = 12 if region == 9 
replace reg_new = 14 if region == 10
replace reg_new = 15 if region == 11
replace reg_new = 16 if region == 12
replace reg_new = 7 if region == 13
replace reg_new = 13 if region == 14
replace reg_new = 1 if region == 15

*antigua region biobio
replace reg_new = 11 if region == 8 & provincia != 84

*nueva region ñuble
replace reg_new = 10 if region == 8 & provincia == 84

save "personas_reg_new.dta" , replace


keep p12a_tramo reg_new p10

rename p10 lugar_habitual
rename p12a_tramo inmigrante
drop if lugar_habitual==99
drop if inmigrante==99
gen extranjero=1 if inmigrante!=98
replace extranjero=0 if inmigrante==98

gen chileno=1 if inmigrante==98
gen foraneos=1 if inmigrante!=98

collapse (sum) chileno foraneos, by(reg_new)
save "replica_tabla2.dta", replace

collapse (sum) chileno (sum) foraneo
 
save "replica_tabla2_totales.dta", replace
clear
use "replica_tabla2.dta"
append using replica_tabla2_totales.dta

replace reg_new=17 if reg_new==.

gen personas_res=chileno+foraneos

gen p_fila=foraneo/(personas_res)*100

gen p_col=foraneo/foraneo[17]*100


label define nombre_region 1"Arica Y Parinacota" 2"Tarapacá" 3"Antofagasta" 4"Atacama" 5"Coquimbo" 6"Vaparaiso" 7"Metropolitana" 8"O'Higgins" 9"Maule" 10"Ñuble" 11"Bio Bio" 12"La Araucania" 13"Los Rios" 14"Los Lagos" 15"Aysen" 16"Magallanes" 17"total"
label values reg_new nombre_region
rename reg_new Regiones_
list Regiones_ foraneo personas_res p_fila p_col
 

save "replica_tabla_2_final.dta", replace
export excel using "replica_tabla_final", sheetreplace firstrow(variables)
clear
//---------------PREGUNTA 2--------------

cd "$log"
capture log close 
log using "replica_tabla_4.log", text replace 
cd "$data_procesada"
use "personas.dta"


keep area p17
rename p17 trabajo
drop if trabajo==98
drop if trabajo==99
replace trabajo=1 if trabajo<=3 // 1 -> si trabajo En la encuesta toman encuenta a las personas que tenian trabajo pero estuvieron de vacaciones,licencia o descanso laboral.
replace trabajo=0 if trabajo>=3 // 0-> no trabajo

label define area_0 1"URBANO" 2"RURAL"
label values area area_0

label define trabajo_0 1"SI TRABAJO LA SEMANA PASADA" 0"NO TRABAJO LA SEMANA PASADA"
label values trabajo trabajo_0

label var trabajo "TRABAJO O NO TRABAJO LA SEMANA PASADA"



tab trabajo area, rowsort

save "personas_trabajo_filtrado.dta", replace
clear

//-----------PREGUNTA 3-------------
cd "$log"
capture log close 
log using "inmigrantes_10.log", text replace 
cd "$data_procesada"
use "personas.dta"

keep comuna p12

rename p12 inmigracion

drop if inmigracion>=98

replace inmigracion=0 if inmigracion<=2 // 0 -> si no son inmigrantes
replace inmigracion=1 if inmigracion>2 // 1 -> son inmigrantes

label define mig 1 "INMIGRANTES" 0"CHILENOS"
label values inmigracion mig
gen chileno=1 if inmigracion==0
gen extranjero= 1 if inmigracion==1

collapse (sum) chileno extranjero , by(comuna)
save "tabla_emigrantes.dta",replace
clear
cd"$data_etiqueta_geo"
import delimited "Microdato_Censo2017-Comunas.csv" , delimiter(";")
cd "$data_procesada"
save "etiqueta_comunas.dta",replace
clear
use "tabla_emigrantes.dta"

merge m:1 comuna using etiqueta_comunas.dta, nogenerate
order nom_comuna, first
gen p_exchange=extranjero/(extranjero+chileno)*100
gsort -p_exchange
list in 1/10
keep in 1/10

save "top_10_inmigrantes.dta", replace
export excel using "top_10_inmigrantes", sheetreplace firstrow(variables)
clear
exit
//-------------------------------------


