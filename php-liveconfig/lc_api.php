<?php

class LC_SOAP_API {

	private $api_url;
	private $api_user;
	private $api_pass;
	private $wsdl_url;

	public function __construct($api_url,$api_user,$api_pass) {

		$this->api_url 		= $api_url;
		$this->api_user 	= $api_user;
		$this->api_pass 	= $api_pass;

		$this->wsdl_url		= $this->api_url 
					. '?wsdl' 
					. '&l=' . urlencode($this->api_user)
					. '&p=' . urlencode($this->api_pass);

	}

	public function create_email_user($email_address,$subscription,$password) {

  		list( $mail_user_part,$mail_domain_part ) = $this->parse_email($email_address);

		$data = [
			'subscription' 	=> $subscription,
			'name'		=> $mail_user_part,
			'domain'	=> $mail_domain_part,
			'mailbox'	=> 1,
			'password'	=> $password,
			'weblogin'	=> 1,
			'autoresponder'	=> 0,
			'autosubject'	=> "Abwesenheitsinformation",
			'automessage'	=> "Guten Tag,\n\nvielen Dank für Ihre Nachricht. Ich bin momentan leider nicht erreichbar.\n\nViele Grüße",
			'quota'		=> 500 ];

		return $this->soap_request("HostingMailboxAdd",$data);
	}

	public function pwreset_email_user($email_address,$subscription,$password) {

		$data = [
			'subscription' 	=> $subscription,
			'address'	=> $email_address,
			'mailbox'	=> 1,
			'password'	=> $password ];

		return $this->soap_request("HostingMailboxEdit",$data);
	}

	private function parse_email($email_address) {

		list( $mail_user_part,$mail_domain_part ) = explode('@',$email_address);
		return [ strtolower($mail_user_part),strtolower($mail_domain_part) ];
	}

	private function soap_request($api_function_name,$data) {

	  $response 	= NULL;
	  $soapFault	= NULL;

	  $ts 		= gmdate("Y-m-d") . "T" . gmdate("H:i:s") . ".000Z";

	  $data["auth"]	= array('login'     => $this->api_user,
				'timestamp' => $ts,
				'token'     => $this->create_token($api_function_name,$ts));

	  $client 	= $this->create_soap_client();
	  try {
		  $response 	= $client->{$api_function_name}($data);
	  } catch (SoapFault $soapFault) {
		# -- command failed
	  }
	  return [$response,$soapFault];


	}

	private function create_soap_client() {
		  return new SoapClient($this->wsdl_url,
				   array('style'    => SOAP_DOCUMENT,
					 'use'      => SOAP_LITERAL,
					)
			  );
	}

	private function create_token($api_function_name,$ts) {
		return base64_encode(hash_hmac('sha1',
				'LiveConfig' 
				. $this->api_user 
				. $api_function_name 
				. $ts,
				$this->api_pass,
					   true)
                        );
	}
}

?>
