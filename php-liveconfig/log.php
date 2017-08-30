<?PHP

$log_level = 3;
$levels = [ "ERROR", "INFO", "DEBUG" ];

function lg_write($msg,$level) {
        global $log_level, $levels;
        if($level <= $log_level) {
                print(date("c").sprintf(" %-5s",$levels[$level])." $msg\n");
        }
}

function lg_debug($msg) { lg_write($msg,2); }
function lg_info ($msg) { lg_write($msg,1); }
function lg_err  ($msg) { lg_write($msg,0); }

?>
