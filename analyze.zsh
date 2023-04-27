#!/usr/bin/env zsh
inputfile="${1:-datasets/data.jsonl}"
model="${2:-gpt-4}"

while read data; do
  sgpt --role events_analyzer --model ${model} <<< "${data}" | jq -c .
done < ${inputfile}
