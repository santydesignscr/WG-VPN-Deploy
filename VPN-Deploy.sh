echo 'You need a port from HAX IPv4 Gateway to access IPv6: \n
    IP Address: Select any that you want from the list \n
    Port: Use any available from 1000 to 10000 \n
    Protocol: UDP \n
    Your IPv6 Address: VPS IPV6 address \n
    Port: Same selected before \n
\n
Now you need to get a domain and add the DNS records: \n
    First you need to create a A record with the IP Address from HAX IPv4 Gateway to access IPv6 Proxy disabled \n
    Add a AAA record with the VPS IPV6 Proxy disabled \n
    Add a AAA record with the VPS IPV6 Proxy enabled \n
    The A record and the AAA record with proxy disabled need to have the same record name and use diferent for the another AAA record (The record with proxy enabled will be your URL for the WireGuard UI)'

wget -N https://raw.githubusercontent.com/fscarmen/warp/main/menu.sh
printf '1\n 3\n' | bash menu.sh 4

echo 'You need to setup your WireGuard server: \n
    1. Public IPv4 address / hostname: Your domain where you added IPV6 and IPV4 \n
    2. IPV6 used: Most times option 1 but check what is the correct VPS IP (See it in VPS Info page) \n
    3. WireGuard Port: The one that you get from HAX IPv4 Gateway to access IPv6 \n
    4. Name for first client: Any that you want without spaces. \n
    5. DNS server for client: Option 1 \n
    6. WireGuard Auto-Updates: Select y (yes)'
read -p "Press enter to continue"
wget https://git.io/wireguard -O wireguard-install.sh && bash wireguard-install.sh

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p
cd /etc/wireguard

cat <<EOF > /etc/wireguard/start-wgui.sh
#!/bin/bash
cd /etc/wireguard
./wireguard-ui -bind-address 0.0.0.0:80
EOF

chmod +x start-wgui.sh

cat <<EOF > /etc/systemd/system/wgui-web.service
[Unit]
Description=WireGuard UI
[Service]
Type=simple
ExecStart=/etc/wireguard/start-wgui.sh
[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/wireguard/update.sh
#!/bin/bash
VER=\$(curl -sI https://github.com/ngoduykhanh/wireguard-ui/releases/latest | grep
"location:" | cut -d "/" -f8 | tr -d '\r')
echo "downloading wireguard-ui \$VER"
curl -sL "https://github.com/ngoduykhanh/wireguardui/releases/download/\$VER/wireguard-ui-\$VER-linux-amd64.tar.gz" -o wireguard-ui-
\$VER-linux-amd64.tar.gz
echo -n "extracting "
tar xvf wireguard-ui-\$VER-linux-amd64.tar.gz
echo "restarting wgui-web.service"
systemctl restart wgui-web.service
EOF

chmod +x /etc/wireguard/update.sh
./update.sh

cat <<EOF > /etc/systemd/system/wgui.service
[Unit]
Description=Restart WireGuard
After=network.target
[Service]
Type=oneshot
ExecStart=/bin/systemctl restart wg-quick@wg0.service
[Install]
RequiredBy=wgui.path
EOF

cat <<EOF > /etc/systemd/system/wgui.path
[Unit]
Description=Watch /etc/wireguard/wg0.conf for changes
[Path]
PathModified=/etc/wireguard/wg0.conf
[Install]
WantedBy=multi-user.target
EOF

touch /etc/wireguard/wg0.conf
systemctl enable wgui.{path,service} wg-quick@wg0.service wgui-web.service
systemctl start wgui.{path,service}

echo 'Due an error of WireGuard admin user is broken, Replace "password": "" with "password": "admin"'
read -p "Press enter to continue"
nano /etc/wireguard/db/users/admin.json

echo 'You need to update some global settings in WireGuard UI: \n
    1. Change endpoint_address value to your domain where ypu added the DNS records \n
    2. Change dns-servers values to "1.1.1.1", "2606:4700::1111"'
read -p "Press enter to continue"
nano /etc/wireguard/db/server/global_settings.json

echo 'You need to update WireGuard server settings in WireGuard UI: \n
    1. Change addresses value to "10.7.0.1/24", "fddd:2c4:2c4:2c4::1/64" \n
    2. Change listen_port value to the port you used in HAX IPv4 Gateway to access IPv6 \n
    3. Change post_up value to "iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" \n
    4. Change post_down value to "iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE"'
read -p "Press enter to continue"
nano /etc/wireguard/db/server/interfaces.json

echo 'Notes: \n
    Each time that you change something on the server configuration or add/edit a client on the WireGuard UI click on Apply Config \n
    When you add a new client ::/0 on Allowed IPs to enabled IPV6 internet access for the client \n
    Default username and password for the WireGuard UI is admin, for security reasons change the password for the admin user from the WireGuard UI \n
\n
And Ready, enjoy your VPN'