#!/bin/bash

find ./ -name "*.md" \
    -type f | xargs -I @@ \
    bash -c 'kramdoc \
        --format=GFM \
        --wrap=ventilate \
        --output=./@@.adoc ./@@';
