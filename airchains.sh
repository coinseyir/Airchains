#!/bin/bash

# Kullanıcıdan gerekli bilgileri alma
read -p "Lütfen chainid giriniz (Örn: mychain): " CHAINID
CHAINID="${CHAINID}_1234-1"


# Sistem güncellemeleri ve gerekli yazılımların kurulumu
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git wget htop tmux build-essential jq make lz4 gcc unzip screen
sudo apt install -y curl git jq lz4 build-essential cmake perl automake autoconf libtool wget libssl-dev

# Port açma
ufw allow 16545

# Go kurulumu
cd $HOME
ver="1.21.3"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version

# Dosyaları indirme ve izinleri ayarlama
git clone https://github.com/airchains-network/evm-station.git
wget http://37.120.189.81/airchain_testnet/tracks
chmod +x tracks

cd evm-station
go mod tidy


# local-setup.sh dosyasını düzenleme
sed -i "s/CHAINID=\"\${CHAIN_ID:-stationevm_1234-1}\"/CHAINID=\"$CHAINID\"/" /root/evm-station/scripts/local-setup.sh

# local-setup.sh scriptini tekrar çalıştırma ve çıktıyı kaydetme
/bin/bash ./scripts/local-setup.sh | tee /root/kayıt.txt

# Port ayarları
echo "export G_PORT="16"" >> $HOME/.bash_profile
source $HOME/.bash_profile
sed -i.bak -e "s%:1317%:${G_PORT}317%g;
s%:8080%:${G_PORT}080%g;
s%:9090%:${G_PORT}090%g;
s%:9091%:${G_PORT}091%g;
s%:8545%:${G_PORT}545%g;
s%:8546%:${G_PORT}546%g;
s%:6065%:${G_PORT}065%g" $HOME/.evmosd/config/app.toml
sed -i.bak -e "s%:26658%:${G_PORT}658%g;
s%:26657%:${G_PORT}657%g;
s%:6060%:${G_PORT}060%g;
s%:26656%:${G_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${G_PORT}656\"%;
s%:26660%:${G_PORT}660%g" $HOME/.evmosd/config/config.toml

# Dosyaları değiştirme
cd
wget http://37.120.189.81/airchain_testnet/station-evm
chmod +x station-evm
rm -rf /root/evm-station/build/station-evm
mv station-evm /root/evm-station/build/station-evm

# local-keys.sh scriptini çalıştırma
cd
cd evm-station
# local-keys.sh scriptini çalıştırma ve çıktıyı kaydetme
/bin/bash ./scripts/local-keys.sh | tee /root/kayıt1.txt

# Kullanıcıdan chainid al ve değişiklikleri yap

sudo tee /etc/systemd/system/evmosd.service > /dev/null <<EOF
[Unit]
Description=evmosd node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.evmosd
ExecStart=/root/evm-station/build/station-evm start \
--metrics "" \
--log_level "info" \
--json-rpc.api eth,txpool,personal,net,debug,web3 \
--chain-id "$CHAINID"
Restart=on-failure
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

# Servis ayarları ve başlatma
sudo systemctl daemon-reload
sudo systemctl enable evmosd
sudo systemctl restart evmosd

# Servis loglarını görüntüleme
sudo journalctl -u evmosd -fo cat



echo "Kurulum tamamlandı!"
