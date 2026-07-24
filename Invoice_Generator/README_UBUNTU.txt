SIMKA Invoice Web App - Ubuntu Guide

Install and run locally on Ubuntu:

sudo apt update
sudo apt install -y python3 python3-pip python3-venv unzip
unzip SIMKA_invoice_web_app_ubuntu_ready.zip
cd simka_invoice_web_app_ubuntu
chmod +x start_ubuntu_local.sh start_ubuntu_port3389.sh
./start_ubuntu_local.sh

Open in the Ubuntu browser:
http://127.0.0.1:8000

Run the web app on port 3389:

./start_ubuntu_port3389.sh

Then open from another machine:
http://SERVER-IP:3389

Important: port 3389 is normally used by Remote Desktop/xrdp. If xrdp is already running, the web app cannot use port 3389 at the same time. In that case, keep xrdp on 3389 and run this app on 8000.

Firewall command if you expose the web app directly:
sudo ufw allow 3389/tcp

Stop the app:
Press CTRL+C in the terminal.
