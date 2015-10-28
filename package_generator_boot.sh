#!/bin/bash

apt-get update -y
apt-get install apt-transport-https -y
# Get the Google Linux package signing key.
sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
# Set up the location of the stable repository.
sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_unstable.list > /etc/apt/sources.list.d/dart_unstable.list'
apt-get update -y
apt-get install dart monit git -y
git clone https://github.com/astashov/dartdocorg.git
usermod -m -d /root root
export HOME=/root
export PATH=$PATH:/usr/lib/dart/bin
cd dartdocorg
pub get

echo 'google_cloud:
  // You can generate them at https://console.developers.google.com/project/dartdocs/apiui/credential
  private_key_id: "private_key"
  private_key: "-----BEGIN PRIVATE KEY-----\nprivate_key\n-----END PRIVATE KEY-----\n"
  client_email: "client_email@developer.gserviceaccount.com"
  client_id: "client_id.apps.googleusercontent.com"
  type: "service_account"
cloudflare:
  // You can get them in CloudFlare -> My Account.
  api_key: adb7e2ccafb342aabebfa8d4633501462f4c9
  email: your.user@example.com
  zone: 721fe21ea39123516629b0505fc1457f' > credentials.yaml

echo 'dart_sdk: /usr/lib/dart
pub_cache_dir: /root/.pub-cache
output_dir: /root/dartdocs.org
hosted_url: https://www.dartdocs.org
gcs_prefix: documentation
gcs_meta: meta
gc_project_name: dart-carte-du-jour
gc_zone: us-central1-f
gc_group_name: dartdocs-package-generators
bucket: www.dartdocs.org
install_timeout: 120' > config.yaml

echo 'set daemon 60
set logfile syslog facility log_daemon
set alert dartdocsorg@gmail.com

set mailserver smtp.gmail.com port 587
    username "dartdocsorg@gmail.com" password "blablahblah" using tlsv1
    with timeout 30 seconds

check system $HOST
    if memory usage > 95% then alert

check process package_generator with pidfile /var/run/package_generator.pid
    start = "/dartdocorg/package_generator_monit.sh start"
    stop = "/dartdocorg/package_generator_monit.sh stop"
' > /etc/monit/conf.d/package_generator

chmod 700 /etc/monit/conf.d/package_generator

echo '# rotate logs
0 * * * * root /usr/sbin/logrotate /dartdocorg/logrotate.conf' > /etc/cron.d/logrotate

monit reload
