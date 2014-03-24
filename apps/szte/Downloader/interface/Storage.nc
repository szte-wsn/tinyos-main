#include <TinyError.h>
#include <message.h>
#include <AM.h>

interface Storage {

	/**
	  * Egy 16 bites meres tarolasa, ket 8 bites szammal (egymas utan a bufferban)
	  * data - az adat
	  * N 	 - mekkora az atadando adattomb merete
	  * error SUCCESS sikerult a tarolas
	  * 	  FAIL    ha mar tele van a buffer
	  */ 

	async command error_t store(uint8_t* data);

	/**
	  * Kikerjuk a mereseket
	  * error SUCCESS sikeresen kiadtunk mindent
	  * 	  FAIL   nincs a bufferbe kiveheto adat
	  */

	command error_t take();


	/**
	  * A meresek kikerese megtortent
	  * data - tarolja az adatot
	  */

	event void takeDone();

	/**
	  * Az osszes bufferben levo adat torlese
	  * free - az utolso 4 adatsor, amit torolnie kell
	  */

	command error_t delete(uint8_t* del);

	/**
	  * A torles befejezodott
	  */
	
	event void deleteDone();

	/**
	  * Ha a base-nek elkuldi a kert szeletet
	  * mes_id melyik meresbol
	  * slice melyik szeletet kuldjuk ujra
	  * error SUCCESS sikeresen lefutott a parancs
	  *       FAIL    ures a buffer
	  */
	
	command error_t getSlice(uint8_t mes_id, uint8_t slice);

	/**
	 * A kommunikacio befejezodott a Base stationnel. Minden adat el lett kuldve.
	 */

	command error_t commEnd();

}
