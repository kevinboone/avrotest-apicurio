#!/bin/bash
rm -rf sender/target
rm -rf receiver/target
find . -name Bear.java -exec rm {} \;
find . -name *.avsc -exec rm {} \;

