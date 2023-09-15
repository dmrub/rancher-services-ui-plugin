#!/usr/bin/env bash

set -eo pipefail

THIS_DIR=$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

cd "$THIS_DIR";

rm -rf assets extensions tmp charts dist-pkg;
