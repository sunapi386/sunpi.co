#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Requires a CLIENTNAME"
  exit
fi

OVPN_DATA="ovpn-data"
CLIENTNAME=$1
DOMAIN="udp://"$CLIENTNAME".sunpi.co"
echo $DOMAIN

# Make container that will hold the configuration files and certificates
docker volume create --name $OVPN_DATA
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u $DOMAIN
docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki

# Start OpenVPN server process
docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn

# Generate a client certificate /with/ a passphrase (nopass at end otherwise)
docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full $CLIENTNAME
# Retrieve the client configuration with embedded certificates
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn

echo "mv $CLIENTNAME.ovpn /var/www/html"
mv $CLIENTNAME.ovpn /var/www/html
echo "<p>Download <a href=\"/$CLIENTNAME.ovpn\">$CLIENTNAME.ovpn</a></p>"
# '<p>Download <a href=/tokyo.ovpn>tokyo.ovpn</a></p>'
