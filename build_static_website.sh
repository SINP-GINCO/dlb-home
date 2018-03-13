#!/bin/bash
# set -xe

#------------------------------------------------------------------------------
# Build the static website from the Symfony 3.4 one, in the "www" directory
# Build before commiting and deploying
# * copy the assets, keeping directory structure
# * generate the html pages and put them in /www (no / in path)
# todo: list the routes from the debug:router command and make a loop on it
#------------------------------------------------------------------------------

function findAFreePort() {
    occupied_ports=$(netstat -aunt | grep "^.*127.0.0.1:" | sed "s/^.\{30\}\([[:digit:]]*\).*$/\1/")
    read lowerPort upperPort < /proc/sys/net/ipv4/ip_local_port_range
    for (( port = lowerPort ; port <= upperPort ; port++ )); do
        available="false"
        for occ_port in $occupied_ports; do
            if [ $occ_port == $port ]; then
                continue 2
            fi
        done
        available="true"
        break
    done
    if [ $available == "false" ]; then  # the loop ended because there were no availables ports
        echo "Pas de port disponible !!!"; exit 1
    fi
    echo $port
}

# Directory of the current script
projectDir=$(dirname $(readlink -f $0))

#-- Copy the assets

rsync -rv $projectDir/public/ $projectDir/www/ --delete --exclude=*.php --exclude=.htaccess

#-- Generates the html files from routes

# Run built in server
freePort=$(findAFreePort)
php bin/console server:start 127.0.0.1:$freePort
sleep 1

# todo: list the routes from the debug:router command and make a loop on it
# todo: instead of listing here the pages
# php bin/console debug:router |awk '$2 == "ANY" {print $5}'

curl --noproxy "*" 127.0.0.1:$freePort/ > $projectDir/www/index.html
curl --noproxy "*" 127.0.0.1:$freePort/mentions-legales > $projectDir/www/mentions-legales.html

# stop server
php bin/console server:stop

# Add newly generated files to git
git add -v --all $projectDir/www/