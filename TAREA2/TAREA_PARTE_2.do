//-----------PARTE2------------------------

clear
version 12
set more off
cap log close


global data  "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/data" // base de datos de las personas e ingresos
global data_etiqueta_per "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/etiqueta_persona" //etiquetas de las personas
global data_etiqueta_geo "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/identif_geo" //data etiqueta geograficas
global data_parte_2 "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/data_parte_3" // data generado de esta parte (hay que crear la carpeta)
global log "/Users/gerardo/Google Drive/Universidad/CICLO9-XCHANGE/ECD/TAREAS/Datos Censo Tarea 2/log" //carpeta para el log

cd "$log"
capture log close 
log using "replica_tabla_2.log", text replace 

cd "$data"

import delimited "personas.csv" , delimiter (";")

cd"$data_parte_2"
save "personas.dta", replace

*NOTA: TODAS LAS TABLAS DE CADA PREGUNTA SE EXPORTAN AUTOMATICAMENTE A EXCEL Y SE GUARDARAN EN LA CARPETA "data_parte_3" del equipo.

*----------PREGUNTA 1---------------------------------------------------------------------------------


*¿Qué porcentaje de la población vive en la misma comuna donde nació?

clear
cd "$data_parte_2"
use "personas.dta"
drop if p12==99 //recortamos valores missing
rename p12comuna comuna_nacimiento //esta es la comuna donde nacieron las personas que marcaron la opcion 2 de la pregunta 12

replace comuna_nacimiento=comuna if comuna_nacimiento==98 & p12==1  //los que marcaron 1 son los que siempre han vivido en la misma comuna en los datos se refleja con el numero 98 para saber la comuna de nacimiento la igualamos con su comuna actual
gen dejar_comuna=1 if comuna_nacimiento!=comuna & comuna_nacimiento!=98 // si las comunas no coinciden y ademas la comuna de nacimiento es difernte a 98-> 98 ahora represente extranjeros quiere decir que DEJARON LA COMUNA DE NACIMIENTO 
gen quedarse_comuna=1 if comuna_nacimiento==comuna // los que se quedaron tienen la misma comuna de nacimiento y comuna actual

save "personas_p.dta", replace
clear
cd"$data_etiqueta_geo"
*le pondre nombre a los codigos de las comunas
import delimited "Microdato_Censo2017-Comunas.csv" , delimiter(";")
cd "$data_parte_2"

rename comuna comuna_nacimiento // le ponemos el mismo nombre para poder hacer merge

save "etiqueta_comunas.dta",replace
clear

use "personas_p.dta"

merge m:1 comuna_nacimiento using etiqueta_comunas.dta

keep nom_comuna comuna_nacimiento comuna p12 dejar_comuna quedarse_comuna p08 p13 p15 p15a

drop if nom_comuna=="" & comuna_nacimiento!=98 //hay comunas de nacimiento con valores 2000,3000,4000,5000,6000,...,14000 que no son codigos de ninguna comuna por lo que no tendran nombre por ellas las cortamos
save "personas_dejaron_quedaron.dta", replace //nuevo base de datos que identifica las personas que se fueron y quedaron de/en la comuna

rename nom_comuna nom_comuna_nacimiento //para identificar mejor la comuna de origen
*el objetivo es crear una bd con la comuna de origen y la comuna actual indentificadas cada una con sus nombres
rename comuna comuna_actual
save "personas_dejaron_quedaron.dta",replace
use "etiqueta_comunas.dta",clear
rename comuna comuna_actual // mismo nombre para hacer merge
save "etiqueta_comunas_mod.dta",replace

use "personas_dejaron_quedaron.dta",clear


merge m:1 comuna_actual using etiqueta_comunas_mod.dta , nogenerate

rename nom_comuna nom_comuna_llegada // para identificar mejor la comuna de llegada

order comuna_nacimiento nom_comuna_nacimiento comuna_actual nom_comuna_llegada
save "personas_dejaron_quedaron.dta" , replace //para reutilizar en otras preguntas
drop if comuna_nacimiento==98 //-> recortamos extranjeros ya que no sirven para el calculo ( no tiene comuna de origen)


collapse (sum) dejar_comuna quedarse_comuna 

gen p_quedaron =(quedarse_comuna)/(dejar_comuna+ quedarse_comuna )*100
gen p_dejar=(dejar_comuna)/(dejar_comuna+ quedarse_comuna )*100
list

cd "$data_parte_2" 
save "preg1_2.dta",replace
 export excel using "preg1_2", sheetreplace firstrow(variables)

*RESPUESTA: se quedaron el 51.83% de los pobladores en la misma comuna de donde nacieron,.

*------------PREGUNTA 2--------------------------------------------------------------------------------
*¿Qué porcentaje se ha movido a otras comunas?
* Reutilzando el codigo anterior tenemos


*RESPUESTA: el 48.17% de los pobladores se movieron a otras comunas.


*-----------PREGUNTA 3-----------------------------------------------------------------------------------------

/*De las personas que se han movido de comuna, ¿Qué porcentaje se ha movido a comunas cuyos ingresos promedios son 
superiores al ingreso promedio de la comuna de origen?*/

cd"$data"
use "data_ingresos.dta",clear
rename comuna comuna_actual
gen comuna_nacimiento=comuna_actual //para duplicar la columna del codigo de la comuna  y hacer 2 merge con diferentes variables
// una columa de codigos  sera para la comuna de nacimiento y el otro con los mismos codigo para comuna actual
cd"$data_parte_2"
save "data_ingresos.dta",replace

use "personas_dejaron_quedaron.dta",clear // de la pregunta 1
merge m:1 comuna_nacimiento  using data_ingresos.dta , nogenerate // juntamos los datos de ingresos con los de las personas usando la comuna de nacimiento como referencia
rename ypchtot ingresos_nacimiento

merge m:1 comuna_actual using data_ingresos.dta, nogenerate // juntamos los datos de ingresos con los de las personas usando la comuna actual como referencia
rename ypchtot ingresos_actual
*de este manera se obtiene una bd identificando para cada persona el ingreso de su comuna de origen y el de de su comuna actual
save "personas_dejaron_quedaron_ingresos.dta",replace

*limpieza
drop if ingresos_nacimiento==. // los extranjeros no tienen ingresos de la comuna de origen
gen mayor_ingreso =1 if (ingresos_actual-ingresos_nacimiento)>0 // 1 si el individuo se mudo a una comuna con mayor ingreso promeio que su comuna de origen
gen menor_ingreso=1 if (ingresos_actual-ingresos_nacimiento)<0 // 0 si el individuo se mudo a una comuna con menor ingreso promeio que su comuna de origen
*se excluye el valor 0 por que son aquellos que se quedaron en la misma comuna
save "comparacion_ingresos_comuna_sexo_ed.dta",replace
collapse (sum) mayor_ingreso (sum)menor_ingreso // contamos todos los indivudos que se mudaron a una comnua con mayor ingreso promedio y contamos los que se movieron a una con menor ingreso promedio

gen p_mayor=mayor_ingreso/(mayor_ingreso+menor_ingreso)*100
list
save "preg3.dta",replace
 export excel using "preg3", sheetreplace firstrow(variables)
clear

*RESPUESTA: EL 53.50% de las personas se han movido a comunas con mayor ingreso promedio que el de sus comunas de origen.

*---------------PREGUNTA 4-----------------------------------------------------------------------------------------------------------------

*¿Existe diferencia en ese porcentaje para mujeres y hombres? ¿es significativo?
//reutilizare el codigo de la pregunta 3

use "comparacion_ingresos_comuna_sexo_ed.dta",clear // de la pregunta 3 

rename p08 sexo

collapse (sum) mayor_ingreso menor_ingreso, by (sexo)

gen p_mayor=mayor_ingreso/(mayor_ingreso+menor_ingreso)*100
label define sex 1"Hombres" 2"Mujeres"
label values sexo sex
list
save "preg4.dta",replace
 export excel using "preg4", sheetreplace firstrow(variables)
clear
/*RESPUESTA:El 53.01% de hombres se movieron a una comuna con mayor ingreso promedio y el 53.97% de mujeres se 
movieron a una comuna con mayor ingreso promedio, para ambos sexos representa más de la mitad de la población, en términos
relativos un 1% más de mujeres se movieron a otra comuna a pesar de que 1este porcentaje puede considerarse como bajo, este valor nos dice 
que 182729 mujeres más a comparación de los hombres cambiaron de comuna a una con mayores ingresos, por lo que se podría considerar significativo */
*---------------PREGUNTA 5-----------------------------------------------------------------------------------------------------------------
*¿Existe diferencia en ese porcentaje para personas con distintos niveles de educación? ¿es significativo?
//SUPUESTO: para la educacion solo se tendra en cuenta aquellas personas que el nivel declarado lo han terminado.
use "comparacion_ingresos_comuna_sexo_ed.dta",clear //de la pregunta 3

rename p15 educacion
rename p15a nivel_terminado

drop if educacion==99 //valores perdidos
drop if nivel_terminado==1 //recortamos a todos aquellos que declaron que no terminaron sus estudios no incluye a los que no tiene estudios
// generando niveles de educacion 
gen sin_educacion=1 if educacion==98
gen pre_escolar=1 if educacion>=1 & educacion<=3
gen especial=1 if educacion==4
gen basica=1 if educacion>=5 & educacion<=6
gen media=1 if educacion>=7 & educacion<=10
gen superior=1  if educacion>=11 & educacion<=14

collapse (sum)mayor_ingreso menor_ingreso, by(sin_educacion pre_escolar especial basica media superior)

gen p_mayor=mayor_ingreso/(mayor_ingreso+menor_ingreso)*100
gsort -p_mayor
list
save "preg5.dta",replace
export excel using "preg5", sheetreplace firstrow(variables)
clear
/*RESPUESTA: Si existe, de hecho es interesate la información que se puede obtener de ella: más de la mitad de personas 
que cuentan con educación superior se mueven a comunas donde hay mayor ingreso, de hecho los que poseen educación
 superior son los que más se mueven(57,42%). En segundo lugar encontramos a la educación básica con el 52%. Aquellos que 
 poseen solo educación pre escolar son los que más han preferido quedarse en su comuna de nacimiento(podría ser por que 
 actualmente los que hacen pre escolar aún son muy pequeños), de ellos solo el 38.29% ha migrado a otras comunas. 
 Aproximadamente la mitad de las personas sin educación o con educación media han decidido 
 migrar a otras comunas donde hay mayor ingreso.*/
*---------------PREGUNTA 6-----------------------------------------------------------------------------------------------------------------

 *Calcule, para cada comuna del país, cuántas personas "dejaron" la comuna y cuantas "llegaron" a la comuna.

cd "$data_parte_2"
use "personas_dejaron_quedaron.dta",clear //de la pregunta 1
gen llegaron_comuna=1 if p12==2 | comuna_nacimiento==98 //marca 1 para las personas que viven en un lugar diferente al de nacimiento(por lo que en algun punto LLEGARON a la comuna donde estan ahora) y a los extranjeros
save "personas_dejaron_quedaron.dta",replace

collapse (sum) dejar_comuna, by(nom_comuna_nacimiento) //RESPUESTA: personas que dejaron la comuna
list
save "preg6a_personas_dejaron_comuna.dta",replace
export excel using "preg6a", sheetreplace firstrow(variables)
use "personas_dejaron_quedaron.dta",clear

collapse (sum) llegaron_comuna, by(nom_comuna_llegada) // RESPUESTA: personas que llegaron a la comuna
list
save "preg6b_personas_llegaron_comuna.dta",replace
export excel using "preg6b", sheetreplace firstrow(variables)
clear


 
 *---------------PREGUNTA 7-----------------------------------------------------------------------------------------------------------------
* Indique las 10 comunas que han recibido más personas, y las 10 de las cuales se han ido más personas.
use "preg6a_personas_dejaron_comuna.dta",clear
gsort -dejar_comuna
list in 1/10
keep in 1/10
 export excel using "preg7a_ido", sheetreplace firstrow(variables)
//Respuesta: 10 comunas de las que se han ido mas personas:
// Santiago, Concepcion, Valparaiso, San Miguel, Quinta Normal, Providencia, Ñuñoa, Viña del Mar, Temuco, Conchal

use "preg6b_personas_llegaron_comuna.dta",clear
gsort -llegaron_comuna
list in 1/10
keep in 1/10
 export excel using "preg7b_recibido", sheetreplace firstrow(variables)
//Respuesta 10 comunas que han recibido más personas(incluye extranjeros):
//Puente Alto, Maipu ,Santiago, La Florida, Las Condes, Viña del Mar, Antofagasta, Ñuñoa ,San Bernardo, Quilicura
  *--------------------PREGUNTA 8-------------------------------------------------------------
  
  
*ELIMINAMOS TODAS LAS BASES DE DATOS TEMPORALES CREADAS YA QUE CONSUMEN MUCHA MEMORIA
 erase comparacion_ingresos_comuna_sexo_ed.dta
 erase data_ingresos.dta
 erase etiqueta_comunas_mod.dta
 erase personas_dejaron_quedaron_ingresos.dta
 erase personas_dejaron_quedaron.dta
 erase etiqueta_comunas.dta
 erase personas_p.dta
 //erase personas.dta
 
 exit
