<?PHP

class IMAP {

	public static function logintest($host,$user,$pass) {

		lg_debug("Testing IMAP account $user on host $host");
		foreach([  IMAP_OPENTIMEOUT, IMAP_READTIMEOUT, IMAP_WRITETIMEOUT, IMAP_CLOSETIMEOUT ] as $timeout_option ) {
			imap_timeout($timeout_option,1);
		}

		$login_types = [ "%s:143/imap/tls", "%s:993/imap/ssl", "%s:143/imap/notls" ];
		$error_reporting = error_reporting();
		error_reporting(0);
		foreach ($login_types as $connect_string) {
				$connect_string=sprintf('{'.$connect_string.'}',$host);
				$conn=imap_open($connect_string, $user, $pass,0,1);
				$struct = imap_fetchstructure($conn, 1);
				$errs = imap_errors();
				if($conn){
					error_reporting($error_reporting);
					return true;
				}
			}
		if($conn) { imap_close($conn); }
		error_reporting($error_reporting);
		}

}
?>
