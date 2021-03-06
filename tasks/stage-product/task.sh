#!/bin/bash

set -eux

# Copyright 2017-Present Pivotal Software, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function main() {

  local cwd
  cwd="${1}"

  local version
  pushd "${cwd}/pivnet-product"
    version="$(unzip -p *.pivotal 'metadata/*.yml' | grep 'product_version:' | cut -d ':' -f 2 | tr -d ' ' | tr -d "'")"
  popd
  
  echo "version = $version"
  echo "product = $PRODUCT_NAME"
  
  om-linux --target "https://${OPSMAN_URI}" \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     stage-product \
     --product-name "${PRODUCT_NAME}" \
     --product-version "${version}"
  
  om-linux --target "https://${OPSMAN_URI}" \
     --skip-ssl-validation \
     --username "${OPSMAN_USERNAME}" \
     --password "${OPSMAN_PASSWORD}" \
     staged-products | grep $PRODUCT_NAME | grep $version 2>&1 > /dev/null
  
  if [ $? != 0 ]; then
    echo "Exiting with failure because the product did not actually stage."
    exit 99
  fi
}

main "${PWD}"
