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

	public function hosting_lookup($domain) {
	
		lg_debug("LC_API call ".__FUNCTION__." with domain=$domain");
		$error_info = NULL;
		list($res,$soapFault) = $this->soap_request("HostingLookup",["domain" => $domain]);
		if(
				$res  
			and	is_object($res) 
			and 	property_exists($res,"subscription") ) {
			return [ $res->subscription , NULL ];
		} else {
			$error_info = [];
			if ($soapFault) {
				$error_info["message"] 	=  $soapFault->faultstring;
				$error_info["code"]     =  $soapFault->faultcode;
				$error_info["data"]     =  $soapFault;
			} else {
				$error_info["message"]	= "Unknown Error";
				$error_info["code"]     = "99";
				$error_info["response"] = $res;
			}
			return [ NULL, $error_info ];
		}
	}

	public function create_email_user($email_address,$password,$subscription=NULL) {
	
		lg_debug("LC_API call ".__FUNCTION__." with address=$email_address");
  		list( $mail_user_part,$mail_domain ) = $this->parse_email($email_address);

		$subscription = $subscription ? $subscription : ($this->hosting_lookup($mail_domain)[0]);
		lg_debug("subscription: $subscription");

		$data = [
			'subscription' 	=> $subscription,
			'name'		=> $mail_user_part,
			'domain'	=> $mail_domain,
			'mailbox'	=> 1,
			'password'	=> $password,
			'weblogin'	=> 1,
			'autoresponder'	=> 0,
			'autosubject'	=> "Abwesenheitsinformation",
			'automessage'	=> "Guten Tag,\n\nvielen Dank für Ihre Nachricht. Ich bin momentan leider nicht erreichbar.\n\nViele Grüße",
			'quota'		=> 500 ];

		list($res,$soapFault) = $this->soap_request("HostingMailboxAdd",$data);
		if(
				$res 
			and 	is_object($res) 
			and 	property_exists($res,"id")) { 

			return [ true, NULL ];
		} else {
			lg_debug(print_r($res,1));
			$error_info = [];
			if ($soapFault) {
				$error_info["message"] 	=  $soapFault->faultstring;
				$error_info["code"]     =  $soapFault->faultcode;
				$error_info["data"]     =  $soapFault;
			} else {
				$error_info["message"]	= "Unknown Error";
				$error_info["code"]     = "99";
				$error_info["response"] = $res;
			}
			return [ NULL, $error_info ];
		}
	}

	public function pwreset_email_user($email_address,$password,$subscription=NULL) {

		lg_debug("LC_API call ".__FUNCTION__." with address=$email_address");
		$subscription = $subscription ? $subscription : ($this->hosting_lookup($this->parse_email($email_address)[1]));

		if(!$subscription) { return [ NULL, [ "message" => "No subscription provided/found for $email_address" ] ] ; }

		$data = [
			'subscription' 	=> $subscription,
			'address'	=> $email_address,
			'mailbox'	=> 1,
			'password'	=> $password ];

		list($res,$soapFault) = $this->soap_request("HostingMailboxEdit",$data);
		if(
				$res 
			and 	is_object($res) 
			and 	property_exists($res,"status")
			and 	$res->status=="ok" ) {

			return [ true, NULL ];
		} else {
			$error_info = [];
			if ($soapFault) {
				$error_info["message"] 	=  $soapFault->faultstring;
				$error_info["code"]     =  $soapFault->faultcode;
				$error_info["data"]     =  $soapFault;
			} else {
				$error_info["message"]	= "Unknown Error";
				$error_info["code"]     = "99";
				$error_info["response"] = $res;
			}
			return [ NULL, $error_info ];
		}
	}

	private function parse_email($email_address) {

		list( $mail_user_part,$mail_domain_part ) = explode('@',$email_address);
		return [ strtolower($mail_user_part),strtolower($mail_domain_part) ];
	}

	private function soap_request($api_function_name,$data) {

	# print($api_function_name."\n");
	# print_r($data);
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
