<?PHP

//
// Copyright: 	Do what you want with the code
//		http://www.wtfpl.net
//
//
// Example of an report request for the CPS-Report API
//
// Fill in your data and adapt the main program at the end
// of the file if needed

// Connection data: Fill in your data

$customer_id    = "YOUR_CUSTOMER_ID";
$api_user       = "YOUR_USER_NAME";
$api_password   = "YOUR_PASSWORD";
$report_api_url = 'https://orms.cps-datensysteme.de:700/report/';

/* *** Important **

* Only the "master" account can view all data
* IP of the host must be granted within the ORMS-GUI, to be able to access the API
  (It will last up to 24 hours for a grant to be done
* ONly 1 simultaneous connection allowed to the report api

*/

function xml_pretty_print($xml_string) {

        // Print pretty formatted XML-String

        $dom = DOMDocument::loadXML($xml_string);
        $dom->formatOutput = true;
        echo $dom->saveXML($dom->documentElement);

}

function execute_curl_request($url,$XML_request) {

        $curl = curl_init();
        curl_setopt($curl, CURLOPT_URL,$url);
        curl_setopt($curl, CURLOPT_VERBOSE, 0);
        curl_setopt($curl, CURLOPT_POST, 0);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $XML_request);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER,1);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, 0);
        $response = curl_exec ($curl);
        curl_close ($curl);

        return $response;

}

function fetch_report($customer_id,$user,$pass,$report_type="domain",$result_data_type="csv") {

        global $report_api_url;

        # values for report_type(see ORMS_anleitung.pdf)
        #
        #       domain | account | dns | contact | sslcert
        #  
        # values for result_data_types
        #
        #       csv | tab
        #

        $request = 
        "<?xml version='1.0' encoding='utf-8'?>
        <request>
          <auth>
            <cid>$customer_id</cid>
            <user>$user</user>
            <pwd>$pass</pwd>
          </auth>
          <transaction>
                <report>
                    <group>$report_type</group>
                    <data_type>$result_data_type</data_type>
                </report>
            </transaction>
         </request>
        ";

        return execute_curl_request($report_api_url,$request);
}

function get_domains_text($XML_response) {

        // get the only the domain data from the xml response

        $dom    = DOMDocument::loadXML($XML_response);
        $xpath  = new DOMXPath($dom);
	
	// get the first data element with context-attribute "domain"
        $node   = ($xpath->query("//data[@context='domain']"))[0];
        $result = NULL;

	// remove empty lines from result data
        foreach(preg_split("/((\r?\n)|(\r\n?))/", $node->nodeValue) as $line){
                if(!preg_match('/^[[:space:]]*$/',$line)) $result=$result?"$result\n$line":$line;
        }
        return $result;
}

# --- main program start

$XML_response   = fetch_report($customer_id,$api_user,$api_password,"domain","csv");
$result         = get_domains_text($XML_response);
print($result);

?>

