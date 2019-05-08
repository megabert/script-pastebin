// ==UserScript==
// @name     LF_Hide_Ignored_User_Threads
// @author   fork
// @version  1
// @grant    none
// @namespace fork
// @include /https?://www.linuxforen.de/forums/(forumdisplay.php|search.php).*$/
// ==/UserScript==

var hide_users = ["Schneewitchen"];
var debug      = false;

function my_log(msg) {
  if(debug) {
     unsafeWindow.console.log(msg);
  }
}
var list = document.querySelectorAll('.username,.understate')

for (var i = 0; i < list.length; i++) {
    for(var j = 0; j < hide_users.length; j++) {
    if (list[i].textContent == hide_users[j]) {
      var row=list[i].parentElement.parentElement.parentElement.parentElement.parentElement.parentElement;
      my_log("found thread of ignoried user: " +hide_users[j]);
      row.style.display = "none";
      break;
    }
  }
}
