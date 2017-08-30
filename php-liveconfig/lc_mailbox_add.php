#!/usr/bin/env php
<?PHP

#  sample php script to use the LC_SOAP_API

include_once "config.php";
include_once "lc_api.php";

if ( $argc <= 2 ) {
  echo "\nUsage $argv[0] <E-Mailadresse> <Passwort>\n\n";
  echo "\t E-Mailadresse:       z. B.: user.name@domain.com\n";
  echo "\t Passwort:            z. B.: dsfkdshfksdjf\n";
  echo "\n";
  exit(9);
}  

$mail_address = $argv[1];
$mail_passwd  = $argv[2];

$lc_api = new LC_SOAP_API($lc_api_url,$lc_api_user,$lc_api_pass);

list($res,$err) = $lc_api->create_email_user($mail_address,$mail_passwd);
if($res) { 
	print "Success\n"; 
	exit(0);
} else {
	print("Error: ".$err["message"]."\n");
	exit(1);
}
?>
