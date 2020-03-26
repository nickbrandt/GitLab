#!/usr/bin/env bash

set -e

PIN_TYPE="${PIN_TYPE:-pin}"
SPEC_DIR="ee/spec/features/boards"
SPEC_FILE="${SPEC_DIR}/boards_pin_spec.rb"
PIN_DIR="${SPEC_DIR}/pins"

echo "Running pins (${PIN_TYPE})..."

bundle exec spring rspec "${SPEC_FILE}"

for f in ${PIN_DIR}/*.${PIN_TYPE}.html; do
  echo "Cleaning pin ($f)..."
  sed -E -i.bak 's/127.0.0.1:[0-9]+/127.0.0.1/g; s/<!---->//g; s#assets/icons-[0-9a-zA-Z]+\.svg#assets/iconstest.svg#g' "$f"
done

rm ${PIN_DIR}/*.bak

yarn run prettier --write "${PIN_DIR}/*.${PIN_TYPE}.html"

if [ "$PIN_TYPE" = "pin" ]; then
  for f in ${PIN_DIR}/*.${PIN_TYPE}.html; do
    oracle=$(echo $f | sed 's/pin.html$/oracle.html/')
    diff -u $oracle $f
  done
fi
