#!/bin/bash

sudo apt update
sudo apt install -y curl

curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh

sudo systemctl start fluent-bit.service

sudo rm /etc/fluent-bit/fluent-bit.conf

CONF_CONTENT=$(cat <<EOF
[INPUT]
    Name              tail
    Path              /var/log/syslog
    Tag               logs.*

[INPUT]
    Name          exec
    Tag           exec_ipaddress
    Command       curl ifconfig.me
    Interval_Sec  10

[FILTER]
    Name          record_modifier
    Match         exec_ipaddress
    Record        hostname \${HOSTNAME}

[INPUT]
    Name          cpu
    Tag           cpu.local
    Interval_Sec   10

[FILTER]
    Name          record_modifier
    Match         cpu.local
    Record        hostname \${HOSTNAME}

[INPUT]
    Name          mem
    Tag           memory
    Interval_Sec   10

[FILTER]
    Name          record_modifier
    Match         memory
    Record        hostname \${HOSTNAME}

[SERVICE]
    Flush        10
    Parsers_File parsers.conf

[OUTPUT]
    Name         stdout
    Match        *

[OUTPUT]
    Name         http
    Match        *
    Host         kurawa-logs.digitalevent.id
    Port         9428
    Compress     gzip
    URI          /insert/jsonline?_stream_fields=stream,path&_msg_field=log&_time_field=date
    Format       json_lines
    Json_Date_Format iso8601
    Header       AccountID 0
    Header       ProjectID 0
EOF
)

# Simpan isi file ke dalam direktori /etc/fluent-bit/fluent-bit.conf
echo "$CONF_CONTENT" | sudo tee /etc/fluent-bit/fluent-bit.conf >/dev/null

sudo systemctl restart fluent-bit.service
