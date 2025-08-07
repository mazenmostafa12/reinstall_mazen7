#!/bin/bash

set -e

echo "[+] Updating system and installing dependencies..."
sudo apt update -y
sudo apt install -y wget unzip curl nano ufw certbot

echo "[+] Downloading and installing Xray..."
wget https://github.com/XTLS/Xray-core/releases/download/v1.8.0/xray-linux-64.zip
unzip xray-linux-64.zip
sudo mv xray /usr/local/bin/
sudo mkdir -p /etc/xray

echo "[+] Generating config file..."
cat <<EOF | sudo tee /etc/xray/config.json
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "520772c6-2d15-4b18-813b-e0c62fa2b1e1",
            "level": 0,
            "decryption": "none"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/waledpro6.cfd/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/waledpro6.cfd/privkey.pem"
            }
          ],
          "minVersion": "TLSv1.2",
          "maxVersion": "TLSv1.3"
        },
        "wsSettings": {
          "path": "/TELEGEAM@D_S_D_C1"
        }
      }
    },
    {
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/waledpro6.cfd/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/waledpro6.cfd/privkey.pem"
            }
          ]
        }
      }
    },
    {
      "port": 443,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "520772c6-2d15-4b18-813b-e0c62fa2b1e1",
            "level": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/waledpro6.cfd/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/waledpro6.cfd/privkey.pem"
            }
          ]
        },
        "wsSettings": {
          "path": "/TELEGEAM@D_S_D_C1"
        }
      }
    },
    {
      "port": 8388,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [
          {
            "password": "520772c6-2d15-4b18-813b-e0c62fa2b1e1",
            "method": "aes-256-gcm",
            "level": 0
          }
        ],
        "timeout": 300
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/waledpro6.cfd/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/waledpro6.cfd/privkey.pem"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

echo "[+] Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/xray -config /etc/xray/config.json
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

echo "[+] Obtaining SSL certificate..."
sudo certbot certonly --standalone -d waledpro6.cfd

echo "[+] Enabling required firewall ports..."
sudo ufw allow 443/tcp
sudo ufw allow 443/udp
sudo ufw allow 80/tcp
sudo ufw allow 80/udp
sudo ufw allow 8388/tcp
sudo ufw allow 8388/udp
sudo ufw allow 1080/tcp
sudo ufw allow 1080/udp
sudo ufw reload

echo "[+] Reloading systemd and starting Xray service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable xray
sudo systemctl restart xray
sudo systemctl status xray --no-pager
