#!/usr/bin/gawk -f


#
#	Aufruf: ./prog.awk orte.txt haupttext.txt
#

BEGIN {
	# max. Wort-Entfernung
	max_distance=10
}

function pruefe_block(zeile,email,orte) {

	# die funktion sucht jetzt den Block nach den gewuenschten werten ab, ausgehend von der E-Mailadresse
	# die nähesten werte (Stadt, Kategorie) bis zur maximalen Wortentfernung werden zurueckgegeben
	# TODO

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

# nach dem lesen der Orte, orte-regex zusammenbasteln
#
# FNR == 1 trifft nur zu bei der 1. Zeile der 2. Datei(haupttext.txt), weil vorher ja mit 
#          next immer wieder die Zeilenverarbeitung beendet wird
FNR == 1 {
	orte_regex="("
	delim=""
	for(o in orte) {
		orte_regex=orte_regex""delim""o
		delim="|"
	}
	orte_regex=orte_regex")"
	# orte_regex="(bonn|berlin|münchen|...)"
}

# ist in aktueller Zeile(2. Datei!) eine E-Mailadresse enthalten?
match($0,/[a-zA-Z0-9_.+\-]+@[a-zA-Z0-9}-]+\.[a-zA-Z0-9\-.]+[a-zA-Z]/,ary) {
	print "E-Mailadresse entdeckt in Zeile: "FNR" email: "ary[0]
	mail_adresse_entdeckt_in_zeile[FNR]=1
	email_adresse[FNR]=ary[0]
}

# für alle Zeilen(2. Datei!)
{
	# zeilenpuffer mit 10 Zeilen als fifo (neue zeile -> 1 -> 2 -> ... -> 10 -> raus) durchschieben
	for(i=9;i>=1;i--) {
		zeile[i+1]=zeile[i]
		}
	zeile[1]=$0
}

# Haben wir 5 Zeilen vorher eine E-Mailadresse gefunden? 

mail_adresse_entdeckt_in_zeile[FNR-5] == 1 {
	# wir haben jetzt 5 Zeilen gelesen nach dem entdecken einer E-Mailadresse
	# d. h. wir haben jetzt 5 Zeilen vor der E-Mailadresse und 5 Zeilen danach
	print "Pruefe Block von E-Mail "email_adresse[FNR-5]" aus Zeile "FNR-5
	pruefe_block(zeile,email_adresse[FNR-5],orte)
}

END {
	# sind in den letzten 4 Zeilen noch E-Mailadressen gefunden worden, so 
	# wurden die noch nicht verarbeitet, weil Zeilen hier grundsätzlich erst
	# nach dem lesen von 5 weiteren Zeilen verarbeitet werden. Also jetzt prüfen,
	# ob noch etwas offen ist und dass dann verarbeiten
	for(j=4;j>0;j--) {
		if(mail_adresse_entdeckt_in_zeile[FNR-j]) {
			print "Pruefe Block von E-Mail "email_adresse[FNR-j]" aus Zeile "FNR-j
			pruefe_block(zeile,email_adresse[FNR-j],orte)
		}
	}

	# TODO: Nachdem alles untersucht und alle werte gefunden wurden, erfolgt hier die Ausgabe der Daten
}

