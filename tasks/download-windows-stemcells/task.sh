#!/bin/bash

set -eu
wget https://github.com/cosmin/s3-bash/archive/master.zip
unzip master.zip

s3-get -k $access_key -s  /$bucket_name/$file > $file


