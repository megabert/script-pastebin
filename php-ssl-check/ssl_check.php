<?PHP

$self = array_shift($argv);

$openssl_input	= shell_exec("openssl s_client </dev/null 2>/dev/null " . implode(" ",$argv). " -CApath /etc/ssl/certs");

preg_match("/(-----BEGIN CERTIFICATE.*END CERTIFICATE-----)/smi",$openssl_input,$matches);
$cert		= $matches[1];

preg_match("/Verify return code: ([0-9]+) \(([^)]+)\)/",$openssl_input,$matches);
$status_code	= $matches[1];
$status_text	= $matches[2];

$crtinfo	= openssl_x509_parse($cert);


printf("\n"
	."CN	: %-40s\n"
	."Start	: %-40s\n"
	."End	: %-40s\n"
	."Valid	: %d (%s)\n\n",
	$crtinfo["subject"]["CN"],
	date("r",$crtinfo["validFrom_time_t"]),
	date("r",$crtinfo["validTo_time_t"]),
	$status_code,
	$status_text

	);

if(array_key_exists("subjectAltName",$crtinfo["extensions"])) {
	printf("Alternate Names\n\n");
	foreach(explode(", ",$crtinfo["extensions"]["subjectAltName"]) as $san) {
		printf("        %-40s\n",preg_replace("/DNS:/","",$san));
	}

}
print("\n");

// print_r($crtinfo);

?>
