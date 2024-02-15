#!/bin/bash
sudo apt update
sudo apt install -y curl
curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh
systemctl start fluent-bit.service

sudo rm /etc/fluent-bit/fluent-bit.conf

# Isi dari file fluent-bit.conf
CONF_CONTENT=$(cat <<EOF
#[INPUT]
#    name              tail
#    path              /var/log/*.log
#    path_key         path

[INPUT]
    Name              tail
    Path              /var/log/syslog
    Tag               logs.*

#[INPUT]
#    Name     syslog
#    Listen   0.0.0.0
#    Port     5140
#    Parser   syslog-rfc3164
#    Mode     tcp

[INPUT]
    Name          exec
    Tag           exec_ipaddress
    Command       curl ifconfig.me
    Interval_Sec  10

[FILTER]
    Name          record_modifier
    Match         exec_ipaddress
    Record        hostname ${HOSTNAME}
    Record        ip_address "${ENV['CURL_OUTPUT']}"

[INPUT]
    name cpu
    tag  cpu.local
    # Read interval (sec) Default: 1
    interval_sec 10

[FILTER]
    Name          record_modifier
    Match         cpu.local
    Record        hostname ${HOSTNAME}
    Record        ip_address "${ENV['CURL_OUTPUT']}"

[INPUT]
    name   mem
    tag    memory
    interval_sec 10

[FILTER]
    Name          record_modifier
    Match         memory
    Record        hostname ${HOSTNAME}
    Record        ip_address "${ENV['CURL_OUTPUT']}"

#[INPUT]
#    Name          exec
#    Tag           exec_cpu
#    Command       grep -i "CPU" /var/log/syslog
#    Interval_Sec  1

#[FILTER]
#    Name   parser
#    Match  exec
#    Key_Name log
#    Parser json

[SERVICE]
    Flush        10
    Parsers_File parsers.conf

[OUTPUT]
    name stdout
    match *

[OUTPUT]
    name  http
    match *
    host kurawa-logs.digitalevent.id
    port 9428
    compress gzip
    uri /insert/jsonline?_stream_fields=stream,path&_msg_field=log&_time_field=date
    format json_lines
    json_date_format iso8601
    header AccountID 0
    header ProjectID 0
EOF
)

# Simpan isi file ke dalam direktori /etc/fluent-bit/fluent-bit.conf
echo "$CONF_CONTENT" | sudo tee /etc/fluent-bit/fluent-bit.conf >/dev/null

systemctl restart fluent-bit.service
