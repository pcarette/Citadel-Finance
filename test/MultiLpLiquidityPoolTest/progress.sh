#!/bin/bash

# Path to the test plan file
FILE="MultiLpLiquidityPoolTest.tree"

# Total number of test lines starting with "it"
total=$(grep -E "\s*it\s" "$FILE" | wc -l)

# Get line number of the marker (//here)
marker_line=$(grep -n "//here" "$FILE" | cut -d: -f1)

if [ -z "$marker_line" ]; then
  echo "Marker '//here' not found in the file."
  exit 1
fi

# Count "it" lines before the marker
completed=$(head -n $marker_line "$FILE" | grep -E "\s*it\s" | wc -l)

# Compute remaining
remaining=$((total - completed))

# Progress calculation
percent=$(( 100 * completed / total ))

# Draw progress bar
bar_length=50
filled_length=$(( bar_length * completed / total ))
empty_length=$(( bar_length - filled_length ))

filled=$(printf '█%.0s' $(seq 1 $filled_length))
empty=$(printf '░%.0s' $(seq 1 $empty_length))

# Output
echo "Progress: [$filled$empty] $percent% ($completed / $total tests completed)"
