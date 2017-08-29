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
$info="";
if($res) { 
	$result = $res->status; 
} else {
	# if we have an error, we check if the account already exists and just reset the password in this case
	if($soapFault &&preg_match("/Mail address or alias already in use/",$soapFault->faultstring) ) {
	list($res,$soapFault) = $lc_api->pwreset_email_user($mail_address,$subscription,$mail_passwd);
		if($res && $res->status == "ok") {
			$result = "ok";
			$info   = "existing account: pw reset ok"; 
		} else {
			$result = "failed";
			$info   = "existing account: pw reset failed(".$soapFault->faultstring.")";

		}
	} else {
		$result = "failed";
		$info   = "user_create failed(".$soapFault->faultstring.")"; 
	}
}

# print error message on stdout
print("$info\n");

if($result=="failed") {
	exit(1);
}
if($result=="ok") {
	exit(0);
}

#undefined status -> exit with error 2
exit(2);
?>
