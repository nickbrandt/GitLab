#!/bin/sh

output=`git grep -En '^<<<<<<< ' -- . ':(exclude)*.haml' ':(exclude)*.js' ':(exclude)*.rb'`
echo $output
test -z "$output"
