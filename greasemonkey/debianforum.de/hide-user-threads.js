// ==UserScript==
// @name     DF_Hide_User_Threads
// @author   heisenberg
// @version  1
// @grant    none
// @namespace heisenberg
// @include /https://debianforum.de/forum/(search|viewforum)\.php/
// ==/UserScript==

var hide_users = ["BananenBoy","GewaltBrabbler"];
var debug      = false;

function my_log(msg) {
  if(debug) {
     unsafeWindow.console.log(msg);
  }
}

var list = document.getElementsByClassName("username");

for (var i = 0; i < list.length; i++) {
    for(var j = 0; j < hide_users.length; j++) {
    if (list[i].textContent == hide_users[j]) {
      var row=list[i].parentElement.parentElement.parentElement.parentElement;
      my_log("found thread of ignoried user: " +hide_users[j]);
      row.style.display = "none";
      break;
    }
  }
}
