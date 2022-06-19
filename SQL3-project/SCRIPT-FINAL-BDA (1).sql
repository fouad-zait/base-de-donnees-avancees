CREATE TABLESPACE SQL3_TBS DATAFILE'C:\SQL3_TBS.dat' size 100M AUTOEXTEND ON ONLINE;

CREATE TEMPORARY TABLESPACE SQL_TempTBS TEMPFILE 'C:\SQL_TempTBS.dat' SIZE 100M AUTOEXTEND ON;

Create User SQL3 Identified by psw Default Tablespace SQL3_TBS Temporary Tablespace SQL_TempTBS;

grant all privileges to SQL3;

CREATE TYPE temploye as object(NUM_EMP Number(7),NOM_EMP varchar2(30),PRENOM_EMP varchar2(30),ADRESSE_EMP varchar2(100),TEL_EMP varchar2(10)) Not Final;
/
CREATE TYPE tmedecin under temploye(SPECIALITE varchar2(40));
/
CREATE TYPE tservice as object(CODE_SERVICE char(3),NOM_SERVICE varchar2(40),BATIMENT char,directeur ref temploye);
/
CREATE TYPE tinfirmier under temploye (infirmier_service ref tservice,ROTATION char(4),SALAIRE number(10,2)) ;
/
CREATE TYPE tpatient as object(NUM_PATIENT Number(7),NOM_PATIENT varchar2(30),PRENOM_PATIENT varchar2(30),
ADRESSE_PATIENT varchar2(100),TEL_PATIENT varchar2(10),MUTUELLE varchar2(10));
/
CREATE TYPE tchambre as object (chambre_service ref tservice,NUM_CHAMBRE Number(4), chambre_infirmier ref temploye,NB_LITS int);
/
CREATE TYPE thospitalisation as object(hospitalisation_patient ref tpatient,hospitalisation_service ref tservice,hospitalisation_chambre ref tchambre,LIT int);
/
create or replace type tsoigne as object( soigne_patient ref tpatient,soigne_medecin ref temploye);
/

//assossiation infirmier chambre //
CREATE TYPE t_set_ref_chambre as table of ref tchambre;
/
ALTER TYPE tinfirmier add attribute infirmier_chambre t_set_ref_chambre cascade;

CREATE TYPE t_set_ref_soigne as table of ref tsoigne;
/
ALTER TYPE tmedecin add attribute medecin_soigne t_set_ref_soigne cascade;
ALTER TYPE tpatient add attribute patient_soigne t_set_ref_soigne cascade;

CREATE TABLE EMPLOYE of temploye(primary key(NUM_EMP));
CREATE TABLE PATIENT of tpatient(primary key(NUM_PATIENT)) nested table patient_soigne store as table_soigne_patient;
CREATE TABLE SERVICE of tservice(primary key(CODE_SERVICE),foreign key(directeur) references employe,UNIQUE(NOM_SERVICE));
CREATE TABLE SOIGNE of tsoigne(foreign key(soigne_patient) references PATIENT,foreign key(soigne_medecin) references employe);
CREATE TABLE CHAMBRE of tchambre(foreign key(chambre_service)references SERVICE,foreign key(chambre_infirmier)references employe,check(NB_LITS>0));
CREATE TABLE HOSPITALISATION of thospitalisation (foreign key(hospitalisation_patient)references PATIENT,foreign key(hospitalisation_service)references SERVICE,foreign key(hospitalisation_chambre)references CHAMBRE);


alter type tmedecin add member function nbmed (spec varchar2) return numeric cascade;
create or replace type body tmedecin as member function nbmed(spec varchar2) return numeric is
nb number ;
begin
nb:=0;
	SELECT count(treat(value(e) as tmedecin)) into nb  from employe e  where value(e) is of (tmedecin ) AND treat(value(e) as tmedecin).SPECIALITE=spec;
return nb;
end nbmed;
end;
/
alter type tservice add member function nbinfirmierhospitalise (code varchar2,b char ) return numeric cascade;

create or replace type body tservice
as member function nbinfirmierhospitalise(code varchar2,b char ) return numeric is
nb number ;
begin
nb:=0;
if b='i' then 
	SELECT count(*) into nb  from employe e  where value(e) is of (tinfirmier) AND deref(treat(value(e) as tinfirmier).infirmier_service).CODE_SERVICE=code;
	return nb;
elsif b='h' then
	SELECT COUNT (*) into nb from hospitalisation h where h.hospitalisation_service.CODE_SERVICE= code;
	return nb;
end if;
end nbinfirmierhospitalise;
end;
/
alter type tpatient add member function nbmedsoignants return numeric cascade;

create or replace type body tpatient
as member function nbmedsoignants return numeric  is
nb number;
begin
nb:=0;
select count(s.soigne_medecin.NUM_EMP)INTO nb from soigne s where self.NUM_PATIENT=s.soigne_patient.NUM_PATIENT ;
return nb;
end nbmedsoignants;
end;
/


alter type temploye add member procedure verifsalaire  cascade;

create or replace type body temploye
as member procedure verifsalaire is
begin
	if(self is of (tinfirmier) AND treat(self  as tinfirmier).SALAIRE between 10000 AND 30000)then dbms_output.put_line('vérification positive');
	else dbms_output.put_line('vérification negative');
	end if;
end verifsalaire;
end;
/

/*insertion des tables/

/*service*/
INSERT INTO SERVICE VALUES ('CAR','Cardiologie','B',(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=80));
INSERT INTO SERVICE VALUES('CHG','Chirurgie générale','A',(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=34));
INSERT INTO SERVICE VALUES('REA','Réanimation et Traumatologie','A',(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=19));
/*employe*/
INSERT INTO EMPLOYE VALUES (tmedecin(4,'BOUROUBI','Taous','Lotissement Dauphin n°30 DRARIA/ALGER','021356085','Orthopédiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(7,'BOUZIDI','AMEL','En face brigade gendarmerie‐Douera‐Alger','0556863528','Cardiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(8,'LACHEMI','Bouzid','140,Av Ali Khoudja‐El Biar‐Alger','021928568','Cardiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(10,'BOUCHEMLA','Elias','6,hai sidi serhane ‐Khemis El Khechna‐Boumerdes','024873549','Cardiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(12,'HADJ','Zouhir','Cité de la Mosquée Bt 14‐Boufarik‐Blida','025474882',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='REA'),'JOUR',12560.78,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(15,'OUSSEDIK','Hakim','152,rue Hassiba Ben Bouali 1er étage ‐Hamma‐Alger','021653445',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'JOUR',11780.48,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(19,'AAKOUB','Fatiha','Boulvard Colonel Amirouche‐Sfissef‐Sidi Bel Abbas','048595512','Traumatologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(22,'ABAD','Abdelhamid','8 Cours Aissat Idir‐El Harrach‐Alger','021524587',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='REA'),'JOUR',14980.21,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(24,'ABADA','Mohamed','2 rue de l Abreuvoir‐Alger','021737000','Orthopédiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(25,'ABAYAHIA','Abdelkader','53 rue de la gare routière‐Douera‐Alger','021416455',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CAR'),'JOUR',15741.25,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(26,'ABBACI','Abdelmadjid','14 rue Ouabdelkader‐Bejaia','034201409','Orthopédiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(27,'ABBAS','Samira','22 rue ahmaed aoune el harrach‐alger','0664027500','Orthopédiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(29,'ABBOU','Mohamed','RUE CHEIKH BOUAAMAMA 45000‐Naama','049796574',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'JOUR',13582.45,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(31,'ABDELAZIZ','Ahmed','43 avenue du 1er novembre‐Ghardaia','029892979','Anesthésiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(34,'ABDELMOUMEN','Nassima','Cité Kharoubi Bt. 18‐Médéa','025584204','Pneumologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(45,'ABDELOUAHAB','OUAHIBA','cité des vieux moulins BEO‐Bab El Oued‐Alger','021967015',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CAR'),'JOUR',14653.25,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(49,'ABDEMEZIANE','Madjid','Avenue Abane Ramdane,Larbaa Nath Iraten‐Tizi Ouzou','026261311',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='REA'),'JOUR',12565.78,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(50,'ABERKANE','Aicha','Cité des 300 logts N°10‐Bab Ezzouar‐Alger','021248345','Pneumologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(53,'AZOUG','Dalila','64 rue de Tripoli‐Hussein Dey‐Alger','021771170','Traumatologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(54,'BENOUADAH','Mohammed','26,boulevard Said Touati‐Beb el oued‐ALGER','021962035','Pneumologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(57,'ACHAIBOU','Rachid','Rue colonel Zamoum ali‐Tizi Ouzou','026211639',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'JOUR',17654.21,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(64,'ADDAD','Fadila','9 cite el hana‐Oum El Bouaghi‐Alger','032421633','Radiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(71,'AGGOUN','Khadidja','20 rue Mohamed Ben Mohamed‐Béchar','049800695',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CAR'),'NUIT',13357.86,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(73,'AISSAT','Salima','Cité 350 lgts. Bt. 12 n°2 Boumerdes','024819915',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='REA'),'NUIT',14738.29,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(80,'AMARA','Dahbia','Nouvelle villa n°27‐Hammedi‐Boumerdes','024860591','Cardiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(82,'AROUEL','Leila','cite frères SADANE bt 34a‐Guelma','037205906','Orthopédiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(85,'BAALI','Souad','3 rue Aissani Said‐Guelma','037264734','Anesthésiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(86,'BABACI','Mourad','Cité Mohamed Boudiaf bt 04 n° 72‐Djelfa','027875147',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'JOUR',11785.48,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(88,'BACHA','Nadia','Cité des 200 logts Bt f n° A‐Ouled Yaich‐Blida','025436875','Cardiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(89,'BAHBOUH','Naima','Cité bonne fontaine‐CHERAGA‐ALGER','0773298155','Radiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(95,'BADI','Hatem','Secteur sanitaire Hassi messaoud 30500‐Ouargla','029737052',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CAR'),'NUIT',19470.61,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(97,'BAKIR','ADEL','COGRAL 1 RUE DE GAO NOUVEAU PORT‐Alger','0555037013',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'NUIT',11840.26,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(98,'BALI','Malika','Cité HLM,Ain M lila‐Oum El Bouaghi','032449120',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CAR'),'JOUR',14984.21,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(99,'BASSI','Fatima','Cité du 5 juillet bloc 130‐Mostaganem','045217227','Anesthésiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(113,'BEHADI','Youcef','9 rue B Koucha‐Bordj Bou Arreridj','035681165','Pneumologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(114,'BEKKAT','Hadia','Bd colonele amirouche‐Baba Hassen‐Alger','021481514','Traumatologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(116,'BELABES','Abdelkader','Cité nouvelle Mosquée‐Djelfa','027877777',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='REA'),'JOUR',15747.25,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(122,'BELAKERMI','Mohammed','Rue de Palestine Sidi Bel Abbes','048544923','Pneumologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(126,'BELGHALI','Mohammed','100 rue Maski Mhamed‐Tipaza','024496636','Radiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(127,'BELHAMIDI','Mustapha','Route de Saida ‐Sidi Bel Abbes','048560678',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='REA'),'NUIT',12657.38,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(130,'BELKACEMI','Hocine','Medouha tizi‐ouzou','26889885',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'JOUR',13548.45,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(131,'BELKOUT','Tayeb','09,rue Alphonse Daudet les Sources‐Bir Mourad Raïs‐Alger','021448066',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CAR'),'JOUR',14655.25,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(135,'RAHALI','Ahcene','105,Lot Oued Tarfa‐Draria‐ALGER','0557705901','Anesthésiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(139,'FERAOUN','Houria','batiment A,n°11,cité El khelloua‐Bologhine‐Alger','021954629',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'NUIT',20374.82,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(140,'TERKI','Amina','17 Rue Mohammed CHABANI‐Alger Centre‐Alger','021235894','Cardiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(141,'CHAOUI','Farid','13,rue khawarismi ‐Kouba‐Alger','021234163','Traumatologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(144,'BENDALI','Hacine','Cité Sonelgaz N° 31‐Ben Aknoun‐Alger','0663163973','Radiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(151,'CHAKER','Nadia','Cité CNEP Bt 16 Bouzareah‐Alger','0551688473',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'JOUR',17685.21,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(152,'BOULARAS','Fatima','21,rue Ferhat Boussaad‐Alger','021237998','Cardiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(155,'IGOUDJIL','Redouane','Les Vergers Bir mourad rais‐Alger','0552637888',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'NUIT',13335.86,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(162,'GHEZALI','Lakhdar','cité des 62 logts‐staoueli‐Alger','021391333',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'NUIT',13841.29,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(163,'KOULA','Brahim','Cité Ali Sadek N° 59 (SNTP) HAMIZ‐Dar El Beida Alger','020406207',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CAR'),'NUIT',14738.29,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(169,'BELAID','Layachi','Annaba centre‐Annaba','0772452613',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CAR'),'NUIT',12947.61,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(176,'CHALABI','Mourad','14,Route Nationale Hassi Bounif ORAN','041275151',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'NUIT',12184.26,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(179,'MOHAMMEDI','Mustapha','42 Ber El‐Djir‐Oran','0771255642','Anesthésiste',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tmedecin(180,'FEKAR','Abdelaziz','Cité Garidi 1 Bt 38,N° 9‐Kouba‐Alger','021687563','Cardiologue',t_set_ref_soigne()));
INSERT INTO EMPLOYE VALUES(tinfirmier(189,'SAIDOUNI','Wafa','Cité le sahel Bt A 11 Air de France‐Bouzareah‐Alger','021943031',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='REA'),'NUIT',13267.38,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(194,'Yalaoui','Lamia','Lot C N° 99 Draria‐Draria‐Alger','020373667',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'NUIT',22034.82,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tinfirmier(195,'AYATA','Samia','76,Rue Ali Remli‐Bouzareah‐Alger','021930764',(SELECT REF(s) FROM service s WHERE s.CODE_SERVICE='CHG'),'NUIT',12381.29,t_set_ref_chambre()));
INSERT INTO EMPLOYE VALUES(tmedecin(196,'TEBIBEL','Nabila','33,rue du Hoggar‐Hydra‐Alger','021604840','Traumatologue',t_set_ref_soigne()));


 
/*PATIENT*/
INSERT INTO PATIENT VALUES (1,'GRIGAHCINE','Nacer','95,Bd Bougara‐El biar‐Alger','021920313','MNAM',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(3,'ABADA','ABDELHAMID','Rue Des Freres Bouchama Bt A Bloc F N 138‐Constantine','031944128','LMDE',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(6,'ABERKANE','Aboukhallil','CITE 500 LOGTS BT 29 N 02 KHROUB‐ Constantine','031963658','MNH',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(13,'MAHBOUBA','Cherifa','CITE 1013 LOGTS BT 61 KHROUB‐ Constantine','031966095','MAAF',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(14,'ACHEUK','Youcef','Rue Des Freres Khaznadar Bt N 28‐ Constantine','031964664','MGEN',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(21,'ACHOUR','Fadila','CITE 1650 LOGTS BT F8 N 71 AIN SMARA‐ Constantine','031974253','MMA',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(23,'AKROUM','Mohammed','Cité Aïssa Harièche,Bâtiment B,n° 12 18000-Jijel','034497088','CNAMTS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(33,'ADJALI','Temim','lot 212 villa n 52 ain smara‐ Constantine','031974214','CCVRP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(35,'HADJ','Haroun','avenue 1er novembre 54‐Sétif','036834401','MNFTC',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(36,'LATRI','Cherifa','cite 600 logts bt a10 n66‐Sétif','036512093','MAS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(37,'SEDDIK AMEUR','Moussa','cite belkhired hacene bt d39 n°593‐Sétif','036722343','AG2R',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(41,'ZENTOUT','Nazih','47,Rue des Frere Niati– Plateaux-Oran','041400805','MGSP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(43,'CHALABI','Mirali','24 rue Larbi Ben Mhidi-0ran','041292275','MNAM',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(44,'BOUABDALLAH','Reda','7è rue n° 394 Tourville-Arzew-W.Oran','0770920566','LMDE',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(46,'BESALAH','Kaddour','112,coop de 18 fevrier ‐St hubert-Oran','041343241','MNH',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(52,'BOUDJELAL','Salim','15,Rue Miloud Benhaddou– Plateaux-Oran','041407746','MAAF',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(55,'AMARA','Med Sofiane','CITE DAKSI BT 09 N 03 CONSTANTINE','031637827','MGEN',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(56,'AMROUNE','Ahmed Lamine','04 RUE MICHELET CONSTANTINE','031923090','MMA',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(60,'AZZI','Kamel','RUE ABANE RAMDANE N 13 CONSTANTINE','031911002','CNAMTS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(61,'BACHTARZI','Faycal','7,RUE BENMELIEK ( EX RUE PINGET) CONSTANTINE','031912244','CCVRP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(63,'BOUZIDI ','kamal','79 RUE BELOUIZDAD BELCOURT‐Alger','021650220','MNFTC',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(65,'MAICH','Sid‐Ali','87,avenue Ali Khodja ‐El Biar‐Alger ','021925219','MAS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(66,'HAFIZ','Mahmoud','01,lot Houari Boumediènne  .SIDI MOUSSA ‐Alger','0770360116','AG2R',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(67,'OUGHANEM','Mohamed','Diar Es Saada,Bt T,N°2 El Madania,Alger','021279526','MGSP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(68,'SERIR','Mustapha','2,rue ait Boudjemaa ‐ Chéraga‐Alger','021361688','MNAM',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(70,'ZEGGAI','Abdelkader','219 route Ain Elbordj Tissemssilt 38000‐Tissemsilt','046496134','LMDE',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(72,'TAHMI','Lamia','CITE BACHEDJARAH BATIMENT 38 ‐Bach Djerrah‐Alger ','021261446','MNH',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(74,'DIAF AMROUNI','Ghania','43,rue Abderrahmane Sbaa Belle vue‐El Harrach‐Alger ','021526166','MAAF',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(75,'MELEK','Chahinaz','HLM Aissat idir cage 9 3ème etage‐El Harrach‐Alger','021828898','MGEN',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(76,'TECHTACHE','Noura','16,route el djamila‐Ain Benian‐Alger','021306517','MMA',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(77,'TOUATI','Widad','14 Rue des frères aoudia‐El Mouradia‐Alger','021690000','CNAMTS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(78,'MAIDAT','Yassine','cité soumam Bt B1 n° 6‐Boufarik‐Blida','025473974','CCVRP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(79,'CHERIF','Nassim','Avenue hanafi hadjress‐Beni Messous‐Alger','0550084741','MNFTC',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(81,'YOUSFI','Mohamed','Résidence Familiale‐Hussein Dey‐Alger','021479918','MAS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(90,'YASRI','Hocine','6 rue med Fellah Kouba‐Alger','021286589','AG2R',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(91,'BAKIR','Adel','Cogral 1 rue de gao nouveau port alger','0555037013','MGSP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(92,'ABLOUL','Faiza','Cité diplomatique Bt Bleu 14B n°3 Dérgana‐ Alger','021217888','MNAM',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(100,'HORRA','Assia','32 rue Ahmed Ouaked‐Dely Brahim‐Alger','021919105','LMDE',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(101,'MESBAH','Souad','Résidence Chabani‐Hydra‐Alger','021602311','MNH',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(102,'LAAOUAR','Ali','CITÉ 1ER MAI EX 137 LOGEMENTS‐Adrar','049963143','MAAF',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(103,'DRIZI','Djamel','36 hai salem. 2000‐Chlef','027722020','MNAM',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(104,'HADJADJ','Boumediene','EPSP ksar el hirane LAGHOUAT','0661646970','LMDE',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(105,'GROUDA','Houda','EPSP thniet elabed batna','0773516149','MNH',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(107,'MEDJAHED','Ahmed','CITE el naaser‐Ain Touta‐Batna','033835858','MAAF',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(108,'IDJAAD','Mohand','504 logts bt 07‐Akbou‐Bejaia','034353567','MGEN',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(109,'KACI','Ali','08 Rue SEFACENE Ahmed‐El‐Kseur‐Bejaia','034252429','MMA',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(117,'KECIR','Laziz','av hassiba benbouali‐Béjaïa','034217564','CNAMTS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(119,'FENNICHE','Saida','cite de l indépendance larbaa blida','025466475','CCVRP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(120,'KOUBA','Mohamed','CENTRE BENCHAABANE‐Ben Khellil‐Blida','025470276','MNFTC',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(121,'AOUIZ','Messoud','Rue Saidani Abdesslam ‐Ain Bessem‐Bouira','026974956','MAS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(123,'OUADAHI','Djaffar','rue amar makhlouf m chedallah bouira','0554180643','AG2R',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(124,'MIMOUNI','Salah','bp 474 tamanrasset','0550993505','MGSP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(128,'TOUMI','Ahmed','cite 5 juillet BP n° 294‐In Salah‐Tamanrasset','029360311','MNAM',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(133,'TRAD','Abd elkader','El Ogla el Malha‐Tébessa','037447300','LMDE',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(137,'SAADI','Med Tayeb','route strategique 12000‐Tébessa','037481154','MNH',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(138,'HALFAOUI','Redouane','Aderb krima rue des frères benchekra‐Tlemcen','0779719617','MAAF',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(145,'KEDJNANE','Brahim','cité des 48 lgts‐Sougueur‐Tiaret','0663125949','MGEN',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(146,'FADEL','Abderahmane','Cité Rousseau Bt D‐Tiaret','046451212','MMA',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(147,'BENNABI','Ahmed','cité 120 logts bt C n° 11. 15600‐Tigzirt‐Tizi Ouzou','026258494','CNAMTS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(148,'AKIL','Farid','3 rue Larbi Ben M hidi‐Draa El Mizan‐Tizi Ouzou','026234316','CCVRP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(149,'DIAF','Ali','Rue Ali Abdelmoumen‐Tigzirt‐Tizi Ouzou','026259630','MNFTC',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(153,'CHERFI','Rabah','Hassi Bahbah‐Hassi Bahbah‐Djelfa','027863306','MAS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(154,'RABOUZI','Mohamed','Cité Mohamed Chaounan bloc 831‐02‐Djelfa','0665781440','AG2R',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(158,'HMIA','Seddik','25 rue Ben Yahiya‐Jijel','034472300','MGSP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(159,'MERABET','Ourida','19 Av. Ben Yahiya‐Jijel','034472300','MNAM',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(164,'OUALI','Samia','cité 200 logements bt1 n°1‐Jijel','034501028','LMDE',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(166,'HADDAD','Fatiha','rue boufada lakhdarat‐Ain Oulmène‐Setif','036720221','MNH',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(167,'MATI','Djamel','Draa kebila hammam guergour sétif','0664504332','MAAF',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(168,'Maiza','Rima','Cité brarma n 5‐Sétif','0774208681','MGEN',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(171,'RAFFAOUI','Meriem','Rue MERIEM BOUATOURA SETIF','0557541887','MMA',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(172,'ZERARGA','Mustapha','Cité Hachemi D2 N° 18 Sétif','0551269045','CNAMTS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(175,'OUCHERIT','Aissa','43,Rue Larbi Ben Mhidi-Oran','041406670','CCVRP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(181,'GHRAIR','Mohamed','Cité Jeanne d Arc Ecran B5‐Gambetta-Oran','041531208','MNFTC',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(182,'MOUHTADI','Dalila','6,Bd Tripoli-Oran','041391640','MAS',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(184,'CHALAH','Younes','cité des 60logts bt D n° 48‐Naciria‐Boumerdes','024880106','AG2R',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(187,'HAMIDI','Mahfoud','BP 24 G Frantz Fanon‐Boumerdes','0771500169','MGSP',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(188,'TITOUCHE','Mohamed','Cité des 50 logts. Sidi Daoud‐Boumerdes','024891120','MNAM',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(190,'BARKAT','Boubeker','CITE MENTOURI N 71 BT AB SMK Constantine','031688561','LMDE',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(191,'DJAKANI','Mostafa','hai nasr‐Tindouf','049934241','MNH',t_set_ref_soigne());
INSERT INTO PATIENT VALUES(192,'HABABB','khadra','Cité lakssabi‐Tindouf','049922543','MAAF',t_set_ref_soigne());


/*chambre*/
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),101,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=95),3);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),102,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=95),2);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),103,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=95),1);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),104,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=169),3);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),105,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=169),2);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),106,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=169),1);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),201,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=29),4);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),202,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=29),4);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),301,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=57),2);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),302,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=57),2);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),303,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=57),1);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),401,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=130),4);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),402,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=130),4);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),403,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=151),2);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),404,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=151),2);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),405,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=151),1);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),101,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=12),1);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),102,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=12),1);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),103,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=22),2);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),104,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=22),2);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),105,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=49),1);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),106,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=49),1);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),107,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=49),2);
INSERT INTO CHAMBRE VALUES ((SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),108,(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=116),2);

/*soigne*/
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=13),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=4));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=23),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=4));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=63),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=4));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=78),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=4));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=81),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=4));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=100),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=4));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=109),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=7));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=119),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=7));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=133),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=7));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=158),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=7));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=175),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=7));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=191),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=7));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=13),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=8));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=23),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=8));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=35),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=8));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=44),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=8));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=14),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=8));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=72),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=10));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=75),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=10));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=76),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=10));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=92),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=10));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=1),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=19));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=21),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=19));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=55),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=19));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=145),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=24));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=147),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=24));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=35),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=26));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=61),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=26));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=79),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=26));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=101),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=26));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=121),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=27));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=128),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=27));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=146),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=27));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=164),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=27));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=166),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=27));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=184),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=27));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=103),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=31));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=145),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=31));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=182),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=31));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=6),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=34));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=52),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=34));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=61),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=34));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=65),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=34));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=66),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=34));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=119),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=50));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=138),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=50));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=164),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=50));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=171),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=50));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=181),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=50));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=3),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=53));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=33),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=53));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=46),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=53));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=60),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=53));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=70),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=53));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=90),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=53));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=120),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=54));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=147),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=54));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=21),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=64));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=68),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=64));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=76),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=64));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=74),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=80));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=76),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=80));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=108),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=82));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=117),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=82));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=137),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=82));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=159),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=82));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=1),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=85));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=3),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=85));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=6),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=85));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=46),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=85));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=52),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=85));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=76),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=85));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=23),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=88));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=41),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=88));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=52),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=88));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=56),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=88));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=68),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=88));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=77),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=88));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=78),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=88));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=100),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=88));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=103),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=89));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=107),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=89));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=123),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=89));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=182),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=89));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=147),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=89));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=146),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=89));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=137),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=89));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=108),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=99));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=172),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=99));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=123),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=99));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=37),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=113));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=102),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=113));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=81),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=113));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=67),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=113));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=44),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=113));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=41),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=113));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=91),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=114));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=63),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=114));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=36),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=114));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=13),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=114));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=6), (SELECT ref(e) from EMPLOYE e where e.NUM_EMP=114));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=102),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=122));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=91),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=122));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=70),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=122));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=3), (SELECT ref(e) from EMPLOYE e where e.NUM_EMP=126));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=36),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=126));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=41),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=126));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=74),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=126));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=77),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=126));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=68),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=135));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=61),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=135));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=56),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=135));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=55),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=135));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=36),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=135));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=33),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=135));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=21),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=135));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=6), (SELECT ref(e) from EMPLOYE e where e.NUM_EMP=135));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=192),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=140));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=188),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=140));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=187),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=140));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=172),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=140));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=168),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=140));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=148),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=140));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=124),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=140));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=104),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=140));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=190),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=141));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=184),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=141));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=171),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=141));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=153),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=141));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=147),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=141));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=128),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=141));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=117),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=141));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=107),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=141));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=105),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=141));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=192),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=184),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=181),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=159),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=154),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=153),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=145),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=120),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=119),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=108),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=144));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=123),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=152));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=145),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=152));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=167),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=152));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=159),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=152));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=149),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=152));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=192),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=179));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=154),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=179));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=117),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=179));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=105),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=179));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=182),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=180));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=172),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=180));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=105),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=180));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=103),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=180));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=171),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=196));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=159),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=196));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=117),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=196));
INSERT INTO SOIGNE VALUES ((SELECT ref(p) from PATIENT p where p.NUM_PATIENT=108),(SELECT ref(e) from EMPLOYE e where e.NUM_EMP=196));
INSERT INTO SOIGNE VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=117),(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=196));
INSERT INTO SOIGNE VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=159),(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=196));
INSERT INTO SOIGNE VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=172),(SELECT REF(e) FROM employe e WHERE e.NUM_EMP=196));

/*hospitalisation*/
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=1),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=101 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=3),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=102 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=6),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=103 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=21),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=103 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=33),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=104 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=36),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=104 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=37),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=201 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=41),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=201 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=43),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=201 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),3);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=46),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=202 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=52),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=202 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),3);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=55),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=202 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),4);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=56),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=301 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=61),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=301 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=65),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=302 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=66),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=302 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=67),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=303 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=68),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=101 AND DEREF(value(c).chambre_service).CODE_SERVICE='CAR'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=72),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=101 AND DEREF(value(c).chambre_service).CODE_SERVICE='CAR'),3);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=74),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=102 AND DEREF(value(c).chambre_service).CODE_SERVICE='CAR'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=76),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=102 AND DEREF(value(c).chambre_service).CODE_SERVICE='CAR'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=77),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=103 AND DEREF(value(c).chambre_service).CODE_SERVICE='CAR'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=103),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=105 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=105),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=107 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=108),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=107 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=117),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='REA'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=108 AND DEREF(value(c).chambre_service).CODE_SERVICE='REA'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=120),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=401 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=123),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=401 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),4);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=137),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=402 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=145),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=402 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=147),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=402 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),3);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=149),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=403 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=154),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=403 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=159),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=404 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=167),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CHG'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=405 AND DEREF(value(c).chambre_service).CODE_SERVICE='CHG'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=172),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=104 AND DEREF(value(c).chambre_service).CODE_SERVICE='CAR'),1);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=182),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=104 AND DEREF(value(c).chambre_service).CODE_SERVICE='CAR'),3);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=188),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=105 AND DEREF(value(c).chambre_service).CODE_SERVICE='CAR'),2);
INSERT INTO HOSPITALISATION VALUES ((SELECT REF(p) FROM PATIENT p WHERE p.NUM_PATIENT=192),(SELECT REF(s) FROM SERVICE s WHERE s.CODE_SERVICE='CAR'),(SELECT REF(c) FROM CHAMBRE c  WHERE c.NUM_CHAMBRE=106 AND DEREF(value(c).chambre_service).CODE_SERVICE='CAR'),1);
/*insertion dans la table patient_soigne les ref*/
insert into table (select p.patient_soigne from Patient p where num_patient=1)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=1);
insert into table (select p.patient_soigne from Patient p where num_patient=3)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=3);
insert into table (select p.patient_soigne from Patient p where num_patient=6)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=6);
insert into table (select p.patient_soigne from Patient p where num_patient=13)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=13);
insert into table (select p.patient_soigne from Patient p where num_patient=14)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=14);
insert into table (select p.patient_soigne from Patient p where num_patient=21)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=21);
insert into table (select p.patient_soigne from Patient p where num_patient=23)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=23);
insert into table (select p.patient_soigne from Patient p where num_patient=33)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=33);
insert into table (select p.patient_soigne from Patient p where num_patient=35)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=35);
insert into table (select p.patient_soigne from Patient p where num_patient=36)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=36);
insert into table (select p.patient_soigne from Patient p where num_patient=37)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=37);
insert into table (select p.patient_soigne from Patient p where num_patient=41)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=41);
insert into table (select p.patient_soigne from Patient p where num_patient=43)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=43);
insert into table (select p.patient_soigne from Patient p where num_patient=44)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=44);
insert into table (select p.patient_soigne from Patient p where num_patient=46)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=46);
insert into table (select p.patient_soigne from Patient p where num_patient=52)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=52);
insert into table (select p.patient_soigne from Patient p where num_patient=55)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=55);
insert into table (select p.patient_soigne from Patient p where num_patient=56)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=56);
insert into table (select p.patient_soigne from Patient p where num_patient=60)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=60);
insert into table (select p.patient_soigne from Patient p where num_patient=61)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=61);
insert into table (select p.patient_soigne from Patient p where num_patient=63)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=63);
insert into table (select p.patient_soigne from Patient p where num_patient=65)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=65);
insert into table (select p.patient_soigne from Patient p where num_patient=66)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=66);
insert into table (select p.patient_soigne from Patient p where num_patient=67)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=67);
insert into table (select p.patient_soigne from Patient p where num_patient=68)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=68);
insert into table (select p.patient_soigne from Patient p where num_patient=70)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=70);
insert into table (select p.patient_soigne from Patient p where num_patient=72)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=72);
insert into table (select p.patient_soigne from Patient p where num_patient=74)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=74);
insert into table (select p.patient_soigne from Patient p where num_patient=75)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=75);
insert into table (select p.patient_soigne from Patient p where num_patient=76)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=76);
insert into table (select p.patient_soigne from Patient p where num_patient=77)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=77);
insert into table (select p.patient_soigne from Patient p where num_patient=78)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=78);
insert into table (select p.patient_soigne from Patient p where num_patient=79)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=79);
insert into table (select p.patient_soigne from Patient p where num_patient=81)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=81);
insert into table (select p.patient_soigne from Patient p where num_patient=90)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=90);
insert into table (select p.patient_soigne from Patient p where num_patient=91)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=91);
insert into table (select p.patient_soigne from Patient p where num_patient=92)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=92);
insert into table (select p.patient_soigne from Patient p where num_patient=100)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=100);
insert into table (select p.patient_soigne from Patient p where num_patient=101)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=101);
insert into table (select p.patient_soigne from Patient p where num_patient=102)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=102);
insert into table (select p.patient_soigne from Patient p where num_patient=103)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=103);
insert into table (select p.patient_soigne from Patient p where num_patient=104)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=104);
insert into table (select p.patient_soigne from Patient p where num_patient=105)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=105);
insert into table (select p.patient_soigne from Patient p where num_patient=107)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=107);
insert into table (select p.patient_soigne from Patient p where num_patient=108)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=108);
insert into table (select p.patient_soigne from Patient p where num_patient=109)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=109);
insert into table (select p.patient_soigne from Patient p where num_patient=117)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=117);
insert into table (select p.patient_soigne from Patient p where num_patient=119)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=119);
insert into table (select p.patient_soigne from Patient p where num_patient=120)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=120);
insert into table (select p.patient_soigne from Patient p where num_patient=121)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=121);
insert into table (select p.patient_soigne from Patient p where num_patient=123)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=123);
insert into table (select p.patient_soigne from Patient p where num_patient=124)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=124);
insert into table (select p.patient_soigne from Patient p where num_patient=128)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=128);
insert into table (select p.patient_soigne from Patient p where num_patient=133)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=133);
insert into table (select p.patient_soigne from Patient p where num_patient=137)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=137);
insert into table (select p.patient_soigne from Patient p where num_patient=138)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=138);
insert into table (select p.patient_soigne from Patient p where num_patient=145)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=145);
insert into table (select p.patient_soigne from Patient p where num_patient=146)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=146);
insert into table (select p.patient_soigne from Patient p where num_patient=147)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=147);
insert into table (select p.patient_soigne from Patient p where num_patient=148)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=148);
insert into table (select p.patient_soigne from Patient p where num_patient=149)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=149);
insert into table (select p.patient_soigne from Patient p where num_patient=153)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=153);
insert into table (select p.patient_soigne from Patient p where num_patient=154)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=154);
insert into table (select p.patient_soigne from Patient p where num_patient=158)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=158);
insert into table (select p.patient_soigne from Patient p where num_patient=159)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=159);
insert into table (select p.patient_soigne from Patient p where num_patient=164)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=164);
insert into table (select p.patient_soigne from Patient p where num_patient=166)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=166);
insert into table (select p.patient_soigne from Patient p where num_patient=167)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=167);
insert into table (select p.patient_soigne from Patient p where num_patient=168)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=168);
insert into table (select p.patient_soigne from Patient p where num_patient=171)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=171);
insert into table (select p.patient_soigne from Patient p where num_patient=172)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=172);
insert into table (select p.patient_soigne from Patient p where num_patient=175)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=175);
insert into table (select p.patient_soigne from Patient p where num_patient=181)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=181);
insert into table (select p.patient_soigne from Patient p where num_patient=182)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=182);
insert into table (select p.patient_soigne from Patient p where num_patient=184)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=184);
insert into table (select p.patient_soigne from Patient p where num_patient=187)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=187);
insert into table (select p.patient_soigne from Patient p where num_patient=188)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=188);
insert into table (select p.patient_soigne from Patient p where num_patient=190)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=190);
insert into table (select p.patient_soigne from Patient p where num_patient=191)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=191);
insert into table (select p.patient_soigne from Patient p where num_patient=192)
(select ref(s) from soigne s where DEREF(s.soigne_patient).num_patient=192);

/*1ere requette*/
SELECT  p.NOM_PATIENT,p.PRENOM_PATIENT  from patient p WHERE p.mutuelle='MAAF';
/*2eme requette*/
SELECT h.lit,DEREF(value(h).hospitalisation_chambre).NUM_CHAMBRE,
DEREF(value(h).hospitalisation_service).NOM_SERVICE,
DEREF(value(h).hospitalisation_patient).NOM_PATIENT,
DEREF(value(h).hospitalisation_patient).PRENOM_PATIENT ,
DEREF(value(h).hospitalisation_patient).MUTUELLE FROM hospitalisation h 
where UPPER(DEREF(value(h).hospitalisation_patient).MUTUELLE)like 'MN%' AND
DEREF(value(h).hospitalisation_service).CODE_SERVICE in
(select s.CODE_SERVICE from service s where batiment='B');
/*3eme requette*/
select t.NUM_PATIENT,t.nbmedsoignants(),count(distinct(treat(value(e)as tmedecin).SPECIALITE))
 from employe e ,soigne s , patient t 
where t.nbmedsoignants()>3 AND DEREF(value(s).soigne_medecin).NUM_EMP=treat(value(e)as tmedecin).NUM_EMP AND
 DEREF(value(s).soigne_patient).NUM_PATIENT=t.NUM_PATIENT group by(t.NUM_PATIENT,t.nbmedsoignants());

/*4eme requette*/

select distinct AVG( treat(value(e)as tinfirmier).salaire),DEREF(treat(value(e)as tinfirmier).infirmier_service).CODE_SERVICE 
from employe e where value (e)is of(tinfirmier)
group by(DEREF(treat(value(e)as tinfirmier).infirmier_service).CODE_SERVICE) ;

/*5eme requette*/
select s.code_service,s.nbinfirmierhospitalise(s.code_service,'i')/s.nbinfirmierhospitalise(s.code_service,'h') as rapport from service s; 

/*6eme requette*/
select distinct treat(value(e)as tmedecin).NOM_EMP,treat(value(e)as tmedecin).PRENOM_EMP
from employe e,soigne s,hospitalisation h where DEREF(value(s).soigne_medecin).NUM_EMP=treat(value(e)as tmedecin).NUM_EMP AND
DEREF(value(h).hospitalisation_patient).NUM_PATIENT=DEREF(value(s).soigne_patient).NUM_PATIENT  
group by(treat(value(e)as tmedecin).NOM_EMP,treat(value(e)as tmedecin).PRENOM_EMP)
having count (distinct DEREF(value(h).hospitalisation_service).CODE_SERVICE)=(select count (s.CODE_SERVICE) 
from service s);



