#!/usr/bin/env php
<?PHP

#  sample php script to use the LC_SOAP_API

include_once "config.php";
include_once "lc_api.php";

if ( $argc <= 3 ) {
  echo "\nUsage $argv[0] <E-Mailadresse> <LiveConfig-Vertrag> <Passwort>\n\n";
  echo "\t E-Mailadresse:               z. B.: user.name@domain.com\n";
  echo "\t LiveConfig-Vertrag:  z. B.: web3\n";
  echo "\t Passwort:            z. B.: dsfkdshfksdjf\n";
  echo "\n";
  exit(9);
}  

$mail_address = $argv[1];
$subscription = $argv[2];
$mail_passwd  = $argv[3];

$lc_api = new LC_SOAP_API($lc_api_url,$lc_api_user,$lc_api_pass);

list($res,$soapFault) = $lc_api->create_email_user($mail_address,$subscription,$mail_passwd);
if($res) { 
	print "Success: ".$res->status."\n"; 
	exit(0);
} else {
	if($soapFault) {
		print "Error: ".$soapFault->faultstring."\n"; 
		exit(1);
	} else {
		print "Uh Oh! Unkown Error!\n";
		exit(2);
	}
}
?>
