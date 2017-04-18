# Liveconfig lua hooks

## General

These little files enable you to execute scripts whenever
liveconfig runs any of its configuration functions.

Hooks are not defined so far and you can be defined as needed.
Whenever the liveconfig lua configuration is run, the hook 
script will be looked up and if it exists it will be run.

## Installation

**Attention: Carefully test your server after editing lua scripts !!**

1. copy system\_hooks.lua to /usr/lib/liveconfig/lua
2. create directory /usr/share/liveconfig/hooks
3. extend your custom.lua with the line from the here contained custom.lua 
4. copy hooks.conf to /etc/liveconfig/hooks.conf and put in an example hook
5. create a script in /usr/share/liveconfig/hooks with the name of your hook an add executable permissions
6. restart liveconfig and watch /var/log/liveconfig/liveconfig.log if any valid hooks are detected
7. Do some change in liveconfig which will trigger the hook and watch liveconfig.log if the script is actually executed
