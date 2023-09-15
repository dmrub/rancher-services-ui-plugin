#!/usr/bin/env bash

set -eo pipefail

THIS_DIR=$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

cd "$THIS_DIR";

if [[ ! -d "$THIS_DIR/node_modules" ]]; then
    yarn install;
fi

yarn publish-pkgs;
sed -i '/urls:/!b;n;s|- services-ui/|- assets/services-ui/|' index.yaml;
