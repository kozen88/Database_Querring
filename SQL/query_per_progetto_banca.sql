/*
	ATTENZIONE PER IL SEGUENTE PROGETTO DATO CHE IL DATABASE E' IN ITALIANO PER LE INFORMAZIONI CHE ESSO
    CONTIENE IL PROGETTO SARA' REALIZZATO IN TALE LINGUA E QUINDI GLI SCRIPT SQL SARANNO TALI DA LAVORARE 
    SU LINGUA ITALIANO SIA SUI NOMI DELLE COLONNE CHE SARANNO CREATE CHE DEI COMMENTI DEL CODICE. 
	
    OBIETTIVO:
    Si vuole estrarre una tabella dal database che riporti informazioni su di un cliente della 
    banca e sui suoii movimenti di entrata e uscita dai conti in suo possesso. L'idea è quella
    di andare a costruire un dataset che possa in seguito essere utilizzato per task di machine
    learning. 
    
    Per quanto riguarda le caratteristiche della tabella che vogliamo andare ad estrarre, esse sono inerenti al singolo cliente 
    e lo caratterizzano in base alle sue attività bancarie. Di seguito si riportano i campi della tabella che vogliamo ottenere:
    
    - id_cliente (univoco)
    - età
    - Numero di transazioni in uscita su tutti i conti 
    - Numero di transazioni in entrata su tutti i conti
    - Importo transato in uscita su tutti i conti
    - Importo transato in entrata su tutti i conti
    - Numero totale di conti posseduti
    - Numero di conti posseduti per tipologia (un indicattore per tipo, ovvero una clonna o campo per tipo)
    - Numero di transazioni in uscita per tipologia (un indicatore per tipo)
    - Numero di transazioni in entrata per tipologia (un indicatore per tipo)
    - Importo transato in uscita per tipologia di conto (un indicatore per tipo)
    - Importo transato in entrata per tipologia di conto (un indicatore per tipo)
    
    Per cui alla fine otterremo una tabella di 12 colonne la quale potrà essere utilizzata come un dataset per l'addestramento
    di modelli di machine learning una volta elilminata la colonna del id_cliente.  
*/

--  VISUALIZZAZIONE DELLE TABELLE PER CONTROLLARE I DATI CONTENUTI
-- -----------------------------------------------------------------------------------------------------------------

-- pprendiamo visione dei clienti
-- Q1.0
SELECT *
FROM banca.cliente;

-- prendiamo visione dei conti
-- Q1.1
SELECT *
FROM banca.conto;

-- prendiamo visione delle tipologie di conto
-- Q1.2
SELECT *
FROM banca.tipo_conto;

-- prendiamo visione delle transazioni
-- Q1.3
SELECT *
FROM banca.transazioni;

-- prendiamo visione delle tipologie di transizioni
-- Q1.4
SELECT *
FROM banca.tipo_transazione;
-- FINE VISUALIZZAZIONE DELLE TABELLE PER PRENDERE VISIONE DEI CAMPI E DEI DATI ---------------------------------------


-- INIZIO QUERY PER LA RISOLUZIONE DEL PROBLEMA POSTO
-- --------------------------------------------------------------------------------------------------------------------

-- questa query ci permette di ricavare l'età del cliente
-- Q2.0
SELECT id_cliente,
	   data_nascita, 
	   TIMESTAMPDIFF(YEAR, data_nascita, CURRENT_DATE()) AS eta
FROM cliente; 

-- la query ci permette di ottenere il  Numero di transazioni in uscita per ogni conto posseduto da un cliente
-- e cambiando la condizione di filtro e il nome della colonna otteniamo il Numero di transazioni in entrata per ogni conto 
-- posseduto dal cliente. Questa query non rappresenta quanto richiesto dall'esercizio, ma è stat utili per capire come 
-- raccogliere le informazioni dividendole prima per ogni conto in seguito andremo a compattare tale informazione come
-- richiesto dalla traccia
-- Q2.1
-- proviamo con il left join  che ci permette di recuperare anche l'utente con id_cliente = 0
SELECT clt.id_cliente,
       COALESCE(cnt.id_conto, 0) AS id_conto,
       CASE WHEN clt.id_cliente = 0 THEN 0 ELSE COUNT(*) END AS numero_transizioni_uscite_totali -- numero_transizioni_entrate_totali  // da cambiare il nome della colonna quando cambiamo la tipologia di filtro 
FROM cliente as clt
    LEFT JOIN conto AS cnt
    ON clt.id_cliente = cnt.id_cliente
    LEFT JOIN transazioni AS trs
    ON cnt.id_conto = trs.id_conto
    LEFT JOIN tipo_transazione AS tptrs
    ON trs.id_tipo_trans = tptrs.id_tipo_transazione
WHERE segno = '-' OR cnt.id_conto IS NULL -- filtriamo tutte le transazioni in uscita, cambiando con '+' otteniamo le transizioni in entrata 
GROUP BY 1,2
ORDER BY clt.id_cliente;

-- query di check per controllare i conti associati ad un determinatto cliente
-- Q3.0
SELECT clt.id_cliente,
	   cnt.id_conto
FROM cliente as clt
	LEFT JOIN conto AS cnt
	ON clt.id_cliente = cnt.id_cliente
WHERE clt.id_cliente = 10;

-- IMPORTANTE DATO CHE LA QUERY Q2.1 RISULTA AVERE UNA SERIE DI JOIN CHE RENDONO LUNGA LA SCRITTURA DELLA QUERY E  DATO CHE 
-- IL JOIN UTILIZZATO SARA' USATO IN PIU' QUERY ANDIAMO A CREARE UNA VISTA OPPORTUNA DI LAVORO CHE CHIAMEREMO:
-- info_transazioni, la quale ci permetterà di soddisfare le richieste formulate nella traccia
CREATE VIEW info_transazione AS
	SELECT clt.id_cliente,
		   clt.nome,
		   clt.cognome,
		   clt.data_nascita,
		   cnt.id_conto,
		   cnt.id_tipo_conto,
		   tptrs.id_tipo_transazione,
		   trs.data AS data_transazione,
		   trs.importo,
		   tptrs.desc_tipo_trans,
		   tptrs.segno
	FROM cliente as clt
		LEFT JOIN conto AS cnt
		ON clt.id_cliente = cnt.id_cliente
		LEFT JOIN  transazioni AS trs
		ON cnt.id_conto = trs.id_conto
		LEFT JOIN tipo_transazione AS tptrs
		ON trs.id_tipo_trans = tptrs.id_tipo_transazione;        

-- controllo che la vista sia corretta rispetto a quello che volevamo
-- Q3.1
SELECT *
FROM info_transazione
ORDER by id_cliente;

-- INIZIAMO A LAVORARE SUI SINGOLI PUNTI RICHIESTI SFRUTTANDO LA VISTA CREATA
-- la query per: Numero di transazioni in uscita su tutti i conti
-- Q2.2
SELECT id_cliente,
       SUM(CASE WHEN segno = '-' THEN 1 ELSE 0 END) AS numero_uscite_totali
FROM info_transazione
GROUP BY id_cliente
ORDER BY id_cliente;

-- la seguente query permette di ricavare il numero di transazioni in uscita totali per ogni conto posseduto dal cliente
-- tale query non era specificata ma la si è voluta formulare come ulteriore esercizio 
-- Q2.2extra 
SELECT id_cliente,
	   COALESCE(id_conto, 0) AS id_conto,
       CASE WHEN id_cliente = 0 THEN 0 ELSE COUNT(*) END AS numero_transizioni_uscite_totali
FROM info_transazione
WHERE segno = '-' OR id_conto IS NULL
GROUP BY 1,2
ORDER BY id_cliente;

-- la query per: Numero di transazioni in entrata su tutti i conti
-- Q2.3
SELECT id_cliente,
       SUM(CASE WHEN segno = '+' THEN 1 ELSE 0 END) AS numero_entrate_totali
FROM info_transazione
GROUP BY id_cliente
ORDER BY id_cliente;

-- la seguente query permette di ricavare il numero di transazioni in entrata totali per ogni conto posseduto dal cliente
-- tale query non era specificata ma la si è voluta formulare come ulteriore esercizio 
-- Q2.3extra 
SELECT id_cliente,
	   COALESCE(id_conto, 0) AS id_conto,
       CASE WHEN id_cliente = 0 THEN 0 ELSE COUNT(*) END AS numero_transizioni_entrate_totali
FROM info_transazione
WHERE segno = '+' OR id_conto IS NULL
GROUP BY 1,2
ORDER BY id_cliente;

-- la query per: Importo transato in uscita su tutti i conti
-- Q2.4
SELECT id_cliente,
       SUM(CASE WHEN segno = '-' THEN importo ELSE 0 END) AS totale_uscite
FROM info_transazione
GROUP BY id_cliente
ORDER BY id_cliente;

-- la seguente query permette di ricavare l'importo totale in uscita per ogni conto posseduto dal cliente
-- tale query non era specificata, ma la si è voluta formulare come ulteriore esercizio 
-- Q2.4extra 
SELECT id_cliente,
	   id_conto,
       sum(importo) AS totale_uscita
FROM info_transazione
WHERE segno = '-' OR id_conto IS NULL
GROUP BY 1,2
ORDER BY id_cliente;

-- la query per: Importo transato in entrata su tutti i conti
-- Q2.5
SELECT id_cliente,
	   SUM(CASE WHEN segno = '+' THEN importo ELSE 0 END) AS totale_entrate
FROM info_transazione
GROUP BY id_cliente
ORDER BY id_cliente;

-- la seguente query permette di ricavare l'importo totale in entrata per ogni conto posseduto dal cliente
-- tale query non era specificata, ma la si è voluta formulare come ulteriore esercizio 
-- Q2.4extra 
SELECT id_cliente,
	   id_conto,
       sum(importo) AS totale_entrata
FROM info_transazione
WHERE segno = '+' OR id_conto IS NULL
GROUP BY 1,2
ORDER BY id_cliente;

-- la query per: Numero totale di conti posseduti
-- Q2.6 
-- Qui lavoriamo con un nuovo join
SELECT clt.id_cliente,
	   CASE WHEN clt.id_cliente = 0 THEN 0 ELSE COUNT(*) END AS numero_conti 
FROM cliente AS clt 
	LEFT JOIN conto AS cnt
    ON clt.id_cliente = cnt.id_cliente
GROUP BY 1
ORDER BY clt.id_cliente;  
-- oppure lavorando sulla vista info_transazione
-- Q2.7
 SELECT id_cliente,
	   count(distinct id_conto) AS numero_conti 
FROM info_transazione
GROUP BY 1
ORDER BY id_cliente;

-- la query per: Numero di conti posseduti per tipologia (un indicattore per tipo, ovvero una clonna o campo per tipo)
-- Q2.8
SELECT  clt.id_cliente,
		SUM(CASE WHEN cnt.id_tipo_conto = 0 THEN 1 ELSE 0 END) AS numero_conti_base, -- conto tipo 0
		SUM(CASE WHEN cnt.id_tipo_conto = 1 THEN 1 ELSE 0 END) AS numero_conti_business, -- conto tipo 1
		SUM(CASE WHEN cnt.id_tipo_conto = 2 THEN 1 ELSE 0 END) AS numero_conti_privati,  -- conto tipo 2
		SUM(CASE WHEN cnt.id_tipo_conto = 3 THEN 1 ELSE 0 END) AS numero_conti_famiglia  -- conto tipo 3
FROM cliente AS clt
	 LEFT JOIN conto AS cnt 
     ON clt.id_cliente = cnt.id_cliente
GROUP BY clt.id_cliente;

-- la query per Numero di transazioni in uscita per tipologia (un indicatore per tipo)
-- Q2.9 
SELECT clt.id_cliente,
		SUM(CASE WHEN trs.id_tipo_trans = 3 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_acquisti_amazon,
		SUM(CASE WHEN trs.id_tipo_trans = 4 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_rata_mutuo,
		SUM(CASE WHEN trs.id_tipo_trans = 5 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_hotel,
		SUM(CASE WHEN trs.id_tipo_trans = 6 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_biglietto_aereo,
		SUM(CASE WHEN trs.id_tipo_trans = 7 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_supermercato
FROM cliente clt
	 LEFT JOIN conto cnt
     ON clt.id_cliente = cnt.id_cliente
	 LEFT JOIN transazioni trs 
     ON cnt.id_conto = trs.id_conto
GROUP BY clt.id_cliente
ORDER BY clt.id_cliente;

-- la query per Numero di transazioni in entrata per tipologia (un indicatore per tipo)
-- Q4.0 
SELECT clt.id_cliente,
		SUM(CASE WHEN trs.id_tipo_trans = 0 AND trs.importo > 0 THEN 1 ELSE 0 END) AS num_trans_stipendio,
		SUM(CASE WHEN trs.id_tipo_trans = 1 AND trs.importo > 0 THEN 1 ELSE 0 END) AS num_trans_pensione,
		SUM(CASE WHEN trs.id_tipo_trans = 2 AND trs.importo > 0 THEN 1 ELSE 0 END) AS num_trans_dividendi
FROM cliente clt
	 LEFT JOIN conto cnt
     ON clt.id_cliente = cnt.id_cliente
	 LEFT JOIN transazioni trs 
     ON cnt.id_conto = trs.id_conto
GROUP BY clt.id_cliente
ORDER BY clt.id_cliente;

-- la query per Importo transato in uscita per tipologia di conto (un indicatore per tipo)
-- Q4.1
SELECT clt.id_cliente,
		SUM(CASE WHEN trs.id_tipo_trans IN (3, 4, 5, 6, 7) AND trs.importo < 0 AND cnt.id_tipo_conto = 0 THEN trs.importo ELSE 0 END) AS uscite_su_conto_base,
		SUM(CASE WHEN trs.id_tipo_trans IN (3, 4, 5, 6, 7) AND trs.importo < 0 AND cnt.id_tipo_conto = 1 THEN trs.importo ELSE 0 END) AS uscite_su_conto_business,
		SUM(CASE WHEN trs.id_tipo_trans IN (3, 4, 5, 6, 7) AND trs.importo < 0 AND cnt.id_tipo_conto = 2 THEN trs.importo ELSE 0 END) AS uscite_su_conto_privato,
        SUM(CASE WHEN trs.id_tipo_trans IN (3, 4, 5, 6, 7) AND trs.importo < 0 AND cnt.id_tipo_conto = 3 THEN trs.importo ELSE 0 END) AS uscitete_su_conto_famiglia
FROM cliente clt
	 LEFT JOIN conto cnt
     ON clt.id_cliente = cnt.id_cliente
	 LEFT JOIN transazioni trs 
     ON cnt.id_conto = trs.id_conto
GROUP BY clt.id_cliente
ORDER BY clt.id_cliente;

-- la query per Importo transato in entrata per tipologia di conto (un indicatore per tipo)
-- Q4.2 
SELECT clt.id_cliente,
		SUM(CASE WHEN trs.id_tipo_trans IN (0, 1, 2) AND trs.importo > 0 AND cnt.id_tipo_conto = 0 THEN trs.importo ELSE 0 END) AS entrate_su_conto_base,
		SUM(CASE WHEN trs.id_tipo_trans IN (0, 1, 2) AND trs.importo > 0 AND cnt.id_tipo_conto = 1 THEN trs.importo ELSE 0 END) AS entrate_su_conto_business,
		SUM(CASE WHEN trs.id_tipo_trans IN (0, 1, 2) AND trs.importo > 0 AND cnt.id_tipo_conto = 2 THEN trs.importo ELSE 0 END) AS entrate_su_conto_privato,
        SUM(CASE WHEN trs.id_tipo_trans IN (0, 1, 2) AND trs.importo > 0 AND cnt.id_tipo_conto = 3 THEN trs.importo ELSE 0 END) AS entrate_su_conto_famiglia
FROM cliente clt
	 LEFT JOIN conto cnt
     ON clt.id_cliente = cnt.id_cliente
	 LEFT JOIN transazioni trs 
     ON cnt.id_conto = trs.id_conto
GROUP BY clt.id_cliente
ORDER BY clt.id_cliente;


-- -------------------------------- QUERY FINALE PER POTTENERE LA TABELLA DESIDERATA -------------------------------------------------
-- prima di procedere a stendere la query finale per ottenere la tabella denormalizzate per ruscire a gestire le informazioni richieste 
-- andiamo a creare due viste che raccoglieranno le informazioni riguardo a numero transazioni e importi di cui una distinta per ogni conto
-- posseduto dal cliente e l'altra che non fa distinzione tra i conti posseduti dal cliente. In questo modo sarà più semplice procedere
-- alla stesura della query finale.


-- creazione della vista numero_transazioni_e_importi_per_conto che riassume il numero di transizioni
-- e gli importi totali per cliente rispetto ad ogni conto posseduto dal cliente
CREATE VIEW numero_transazioni_e_importi_per_conto AS
	SELECT clt.id_cliente,
			SUM(CASE WHEN trs.id_tipo_trans = 0 AND trs.importo > 0 THEN 1 ELSE 0 END) AS num_trans_stipendio,
			SUM(CASE WHEN trs.id_tipo_trans = 1 AND trs.importo > 0 THEN 1 ELSE 0 END) AS num_trans_pensione,
			SUM(CASE WHEN trs.id_tipo_trans = 2 AND trs.importo > 0 THEN 1 ELSE 0 END) AS num_trans_dividendi,
			SUM(CASE WHEN trs.id_tipo_trans = 3 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_acquisti_amazon,
			SUM(CASE WHEN trs.id_tipo_trans = 4 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_rata_mutuo,
			SUM(CASE WHEN trs.id_tipo_trans = 5 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_hotel,
			SUM(CASE WHEN trs.id_tipo_trans = 6 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_biglietto_aereo,
			SUM(CASE WHEN trs.id_tipo_trans = 7 AND trs.importo < 0 THEN 1 ELSE 0 END) AS num_trans_supermercato,
			SUM(CASE WHEN trs.id_tipo_trans IN (3, 4, 5, 6, 7) AND trs.importo < 0 AND cnt.id_tipo_conto = 0 THEN trs.importo ELSE 0 END) AS uscite_su_conto_base,
			SUM(CASE WHEN trs.id_tipo_trans IN (3, 4, 5, 6, 7) AND trs.importo < 0 AND cnt.id_tipo_conto = 1 THEN trs.importo ELSE 0 END) AS uscite_su_conto_business,
			SUM(CASE WHEN trs.id_tipo_trans IN (3, 4, 5, 6, 7) AND trs.importo < 0 AND cnt.id_tipo_conto = 2 THEN trs.importo ELSE 0 END) AS uscite_su_conto_privato,
			SUM(CASE WHEN trs.id_tipo_trans IN (3, 4, 5, 6, 7) AND trs.importo < 0 AND cnt.id_tipo_conto = 3 THEN trs.importo ELSE 0 END) AS uscitete_su_conto_famiglia,
			SUM(CASE WHEN trs.id_tipo_trans IN (0, 1, 2) AND trs.importo > 0 AND cnt.id_tipo_conto = 0 THEN trs.importo ELSE 0 END) AS entrate_su_conto_base,
			SUM(CASE WHEN trs.id_tipo_trans IN (0, 1, 2) AND trs.importo > 0 AND cnt.id_tipo_conto = 1 THEN trs.importo ELSE 0 END) AS entrate_su_conto_business,
			SUM(CASE WHEN trs.id_tipo_trans IN (0, 1, 2) AND trs.importo > 0 AND cnt.id_tipo_conto = 2 THEN trs.importo ELSE 0 END) AS entrate_su_conto_privato,
			SUM(CASE WHEN trs.id_tipo_trans IN (0, 1, 2) AND trs.importo > 0 AND cnt.id_tipo_conto = 3 THEN trs.importo ELSE 0 END) AS entrate_su_conto_famiglia
	FROM cliente clt
		 LEFT JOIN conto cnt
		 ON clt.id_cliente = cnt.id_cliente
		 LEFT JOIN transazioni trs 
		 ON cnt.id_conto = trs.id_conto
	GROUP BY clt.id_cliente
	ORDER BY clt.id_cliente;
 
-- controlliamo la vista creata numero_transazioni_e_importi_per_conto
SELECT *
FROM numero_transazioni_e_importi_per_conto;

-- creazione della vista numero_transazioni_e_importi_non_distinti_per_conto che riassume il numero di transizioni
-- e gli importi totali per cliente indipendentemente dal numero di conti posseduti
CREATE VIEW numero_transazioni_e_importi_non_distinti_per_conto AS
	SELECT id_cliente,
		   SUM(CASE WHEN segno = '-' THEN 1 ELSE 0 END) AS numero_uscite_totali,
		   SUM(CASE WHEN segno = '+' THEN 1 ELSE 0 END) AS numero_entrate_totali,
		   SUM(CASE WHEN segno = '-' THEN importo ELSE 0 END) AS totale_uscite,
		   SUM(CASE WHEN segno = '+' THEN importo ELSE 0 END) AS totale_entrate,
		   count(distinct id_conto) AS numero_conti 
	FROM info_transazione
	GROUP BY id_cliente
	ORDER BY id_cliente;

-- controlliamo la vista creata numero_transazioni_e_importi_non_distinti_per_conto
SELECT *
FROM numero_transazioni_e_importi_non_distinti_per_conto;

-- procediamo con la stesura della query finale sfruttando le viste create per produrre la tabella denormalizzata richiesta
-- Q_Finale
SELECT clt.id_cliente,
	   TIMESTAMPDIFF(YEAR, data_nascita, CURRENT_DATE()) AS eta,
       nti_ndc.numero_uscite_totali,
       nti_ndc.numero_entrate_totali,
       nti_ndc.totale_uscite,
       nti_ndc.totale_entrate,
       nti_ndc.numero_conti AS numero_conti_posseduti,
       numero_cpt.numero_conti_base,
       numero_cpt.numero_conti_business,
       numero_cpt.numero_conti_privati,
       numero_cpt.numero_conti_famiglia,
       ntic.num_trans_stipendio,
       ntic.num_trans_pensione,
       ntic.num_trans_dividendi, 
       ntic.num_trans_acquisti_amazon,
       ntic.num_trans_rata_mutuo,
       ntic.num_trans_hotel,
       ntic.num_trans_biglietto_aereo,
       ntic.num_trans_supermercato,
       ntic.uscite_su_conto_base,
       ntic.uscite_su_conto_privato,
       ntic.uscitete_su_conto_famiglia,
       ntic.entrate_su_conto_base,
       ntic.entrate_su_conto_business,
       ntic.entrate_su_conto_privato,
       ntic.entrate_su_conto_famiglia
FROM cliente AS clt
     LEFT JOIN numero_transazioni_e_importi_non_distinti_per_conto AS nti_ndc
     ON clt.id_cliente = nti_ndc.id_cliente
     LEFT JOIN numero_transazioni_e_importi_per_conto AS ntic
     ON nti_ndc.id_cliente = ntic.id_cliente
     LEFT JOIN ( SELECT  clt.id_cliente,
						 SUM(CASE WHEN cnt.id_tipo_conto = 0 THEN 1 ELSE 0 END) AS numero_conti_base, -- conto tipo 0
						 SUM(CASE WHEN cnt.id_tipo_conto = 1 THEN 1 ELSE 0 END) AS numero_conti_business, -- conto tipo 1
						 SUM(CASE WHEN cnt.id_tipo_conto = 2 THEN 1 ELSE 0 END) AS numero_conti_privati,  -- conto tipo 2
						 SUM(CASE WHEN cnt.id_tipo_conto = 3 THEN 1 ELSE 0 END) AS numero_conti_famiglia  -- conto tipo 3
				  FROM  cliente AS clt
					    LEFT JOIN conto AS cnt 
					    ON clt.id_cliente = cnt.id_cliente
				  GROUP BY clt.id_cliente) AS numero_cpt
	 ON ntic.id_cliente = numero_cpt.id_cliente;
     
     -- infine evidenziando la querry finale e selezionando cliccando il tab Query selezionando l'opzione Export Result
     -- avremo la possibilità di esportare la tabella risultante dalla query in un file csv il quale potrà essere utilizzato
     -- per caricare i dati con python ed effettuare dei task di machine learning.