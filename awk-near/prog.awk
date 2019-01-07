#!/usr/bin/gawk -f


#
#	Aufruf: ./prog.awk orte.txt haupttext.txt
#

BEGIN {
	# max. Wort-Entfernung
	max_abstand=10
}

function entferne_muell_am_ende(wort,tmp) {
	if(match(wort,"(.*)[.,:-]",tmp)) {
		return tmp[1]
	}
	return wort
}

function finde_naehestes(anker,suchwort,text,max_abstand,	abstand,regex,erg,zielwort) {
	zielwort=""
	for(abstand=1;abstand<=max_abstand;abstand++) {
		# suche suchbegriff nach anker
		regex=anker"[[:space:]]+([^[:space:]]+[[:space:]]+){0," abstand "}" suchwort
		if(match(text,regex,erg)) {
			zielwort=erg[2]
			return zielwort
		}
		# suche suchbegriff vor anker
		regex=suchwort "[[:space:]]+([^[:space:]]+[[:space:]]+){0," abstand "}" anker
		if(match(text,regex,erg)) {
			zielwort=erg[1]
			return zielwort
		}
	}
}

function pruefe_block(zeilen,email,orte_regex,	gesamt,trail_re,kat_regex) {

	# die funktion sucht jetzt den Block nach den gewuenschten werten ab, ausgehend von der E-Mailadresse
	# die nähesten werte (Stadt, Kategorie) bis zur maximalen Wortentfernung werden zurueckgegeben
	# TODO

	print "***pruefe block: *** " email 
	gesamt = join(zeilen)
	trail_re="[.,:-]?"
	#print gesamt
	
	# finde kategorie in Distanz 1-max_distanz
	kat_regex = "kategorie" trail_re "[[:space:]]+([^[:space:]]+)" trail_re 
	kategorie = entferne_muell_am_ende( finde_naehestes(email trail_re,kat_regex,gesamt,max_abstand) )
	print "Mail: " email " Kategorie: " kategorie

} 

function altregex_aus_liste(liste,    regex,delim) {
	# element1 element2 ... elementn -> (element1|element2|...|elementn)
	regex="("
	delim=""
	for(element in liste) {
		regex=regex""delim""element
		delim="|"
	}
	regex=regex")"
	return regex
}

function join(zeilen,     gesamt,zeile) {
	gesamt=""
	for(nr in zeilen) {
		gesamt=zeilen[nr]""gesamt
	}
	return gesamt
}

# Datei mit Orten einlesen
#
# NR  = verarbeitete Zeilen gesamt
# FNR = verarbeitete Zeilen der aktuellen Datei
# 
# FNR == NR: wenn geich, dann sind wir in der ersten Datei(orte!)
# 
FNR == NR {
	orte[$1]=1
	next
} 

# FNR == 1 trifft nur zu bei der 1. Zeile der 2. Datei(haupttext.txt), weil vorher ja mit 
#          next immer wieder die Zeilenverarbeitung beendet wird
FNR == 1 {
	durchlauf=durchlauf+1
	if(durchlauf==1) {
		# nach dem lesen der Orte, orte-regex zusammenbasteln
		orte_regex = altregex_aus_liste(orte) 
	}
	if(durchlauf==2) {
		# nach dem lesen der gefundenen Orte, orte-gefunden-regex zusammenbasteln
		orte_gefunden_regex = altregex_aus_liste(orte_gefunden)
	}
}

# 2. Datei, 1. Durchlauf: tatsächliche Orte Ermitteln
durchlauf == 1 {
	if(match($0,orte_regex,ary)) {
		orte_gefunden[tolower(ary[0])]=1
	}
	next
}

# 2. Datei, 1. Durchlauf: tatsächliche Orte Ermitteln

# ist in aktueller Zeile(2. Datei!) eine E-Mailadresse enthalten?
match($0,/[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9}-]+\.[a-zA-Z0-9\-.]+[a-zA-Z]/,ary) {
	print "E-Mailadresse entdeckt in Zeile: "FNR" email: "ary[0]
	mail_adresse_entdeckt_in_zeile[FNR]=1
	email_adresse[FNR]=tolower(ary[0])
}

# für alle Zeilen(2. Datei!)
{
	# zeilenpuffer mit 10 Zeilen als fifo (neue zeile -> 1 -> 2 -> ... -> 10 -> raus) durchschieben
	for(i=9;i>=1;i--) {
		zeilen[i+1]=zeilen[i]
		}
	zeilen[1]=tolower($0)
}

# Haben wir 5 Zeilen vorher eine E-Mailadresse gefunden? 

mail_adresse_entdeckt_in_zeile[FNR-5] == 1 {
	# wir haben jetzt 5 Zeilen gelesen nach dem entdecken einer E-Mailadresse
	# d. h. wir haben jetzt 5 Zeilen vor der E-Mailadresse und 5 Zeilen danach
	#print "Pruefe Block von E-Mail "email_adresse[FNR-5]" aus Zeile "FNR-5
	pruefe_block(zeilen,email_adresse[FNR-5],orte_gefunden_regex)
}

END {
	# sind in den letzten 4 Zeilen noch E-Mailadressen gefunden worden, so 
	# wurden die noch nicht verarbeitet, weil Zeilen hier grundsätzlich erst
	# nach dem lesen von 5 weiteren Zeilen verarbeitet werden. Also jetzt prüfen,
	# ob noch etwas offen ist und dass dann verarbeiten
	for(j=4;j>0;j--) {
		if(mail_adresse_entdeckt_in_zeile[FNR-j]) {
			# print "Pruefe Block von E-Mail "email_adresse[FNR-j]" aus Zeile "FNR-j
			pruefe_block(zeilen,email_adresse[FNR-j],orte_gefunden_regex)
		}
	}

	# TODO: Nachdem alles untersucht und alle werte gefunden wurden, erfolgt hier die Ausgabe der Daten
}

