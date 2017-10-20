#!/bin/bash

[ "$#" != "7" ] && { echo "<faxfile> <recipient> <callerid> <exten> <remoteid> <pages> <bitrate>"; exit 1; }

FAX_SERVER_SENDER="fax@sipserver.domain.de"
FAX_EMAIL_TARGET="fax@targetdomain.de"

FAXFILE="$1" 
RECIPIENT="$2"
FAXSENDER="$3"
FAXEXTEN="$4"

REMOTESTATIONID="$5"
FAXPAGES="$6"
FAXBITRATE="$7"

DATE="`date "+%Y%m%d-%H%M%S"`"
LOGDATE="`date`"

DOKUSER=`echo $2|sed -e 's/\@/-/g'`
ARCHIVE="/var/spool/asterisk/fax/${DOKUSER}"
FILENAME="${DATE}-${FAXEXTEN}-${FAXSENDER}-${RANDOM}"

[ "$FAXSENDER" == "" ] && FAXSENDER="unbekannt"


umask 0027

{ echo -ne "$LOGDATE\nfile: $FAXFILE\nrecipient: $RECIPIENT\nsender: $FAXSENDER\n\n"; } >> /tmp/fax.log

{
	if [ -s "${FAXFILE}.tif" ]; then
		if [ ! -d "${ARCHIVE}" ]; then
			{ mkdir "${ARCHIVE}" && chown asterisk.doku-sync "${ARCHIVE}"; } 2>>/tmp/fax.log || echo -e "mkdir failed: ${ARCHIVE}.\n\n" >>/tmp/fax.log
		fi
		cp "${FAXFILE}.tif" "${ARCHIVE}/${FILENAME}.tif" 2>>/tmp/fax.log || echo -e "Archive copy failed.\n\n" >>/tmp/fax.log
		cp "${FAXFILE}.tif" "/var/spool/asterisk/archive/fax/${FILENAME}.tif" 2>>/tmp/fax.log || echo -e "Local copy failed.\n\n" >>/tmp/fax.log
		{
			cat <<-__EOF__
			Eingegangenes Fax.

			Datum des Empfangs:        $LOGDATE
			Übermittelte Rufnummer:    $FAXSENDER
			Angewählte Durchwahl:      $FAXEXTEN
			Anzahl empfangener Seiten: $FAXPAGES

			Stationskennung:           $REMOTESTATIONID
			Empfangsbitrate:           $FAXBITRATE


			__EOF__
		} | mime-construct --output --subpart \
			--type "text/plain; charset=iso-8859-1" \
			--encoding quoted-printable --file - |formail -f >"${FAXFILE}.mailtmp.info.txt"
		tifftopnm "${FAXFILE}.tif" | gocr -f ISO8859_1 -i - | mime-construct --output --subpart \
			--type "text/plain; charset=iso-8859-1" \
			--encoding quoted-printable --file - |formail -f >"${FAXFILE}.mailtmp.ocr.txt"
		tiff2pdf "${FAXFILE}.tif" >"${ARCHIVE}/${FILENAME}.pdf"
		mime-construct --output --subpart \
			--type application/pdf \
			--attachment "${FILENAME}.pdf" \
			--encoding base64 \
			--file "${ARCHIVE}/${FILENAME}.pdf" |formail -f >"${FAXFILE}.mailtmp.pdf"
		mime-construct --output --subpart \
			--subpart-file "${FAXFILE}.mailtmp.info.txt" \
			--subpart-file "${FAXFILE}.mailtmp.ocr.txt" \
			--subpart-file "${FAXFILE}.mailtmp.pdf" >"${FAXFILE}.mailtmp"
		mime-construct --output --subpart \
			--subpart-file "${FAXFILE}.mailtmp.info.txt" \
			--subpart-file "${FAXFILE}.mailtmp.ocr.txt" >"${FAXFILE}.mailtmp.plain"
		mime-construct --output \
			--subpart-file "${FAXFILE}.mailtmp" \
			--to "$RECIPIENT" --subject "Fax von ${FAXSENDER}" \
			--header "From: Faxserver <$FAX_SERVER_SENDER>" \
			--header "Reply-To: $FAX_SERVER_SENDER" | /usr/sbin/sendmail -t -f "ne.de"
		mime-construct --output \
			--subpart-file "${FAXFILE}.mailtmp.plain" \
			--to "$RECIPIENT" --subject "Fax von ${FAXSENDER} (ohne Anhang)" \
			--header "From: Faxserver <$FAX_SERVER_SENDER>" \
			--header "Reply-To: $FAX_EMAIL_TARGET" | /usr/sbin/sendmail -t -f "$FAX_EMAIL_TARGET"
	fi
	rm -f "${FAXFILE}.mailtmp.info.txt" "${FAXFILE}.mailtmp.ocr.txt" "${FAXFILE}.mailtmp" "${FAXFILE}.mailtmp.plain" "${FAXFILE}.tif" "${FAXFILE}.mailtmp.pdf"
} 2>>/tmp/fax_err.log
