#!/usr/bin/expect -f

set ip TypeTheIP
set port TypeThePort
set username TypeTheUsername
set password TypeThePassword
set prompt "telnet>"

set argsCount [llength $argv];
set i 0

#telnet
spawn telnet $ip $port

#login
expect "login :"
send "$username\r\n"
expect "password :"
send "$password\r\n"

while {$i < $argsCount } {
    expect "$prompt"
    send "[lindex $argv $i]\r\n"
    incr i
}

expect "$prompt"
send "exit\r\n"

expect eof