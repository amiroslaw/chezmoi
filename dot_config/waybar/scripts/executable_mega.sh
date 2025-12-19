#!/bin/sh

# ERROR column is $6, STATUS column is $5
mega-sync | awk '
NR > 1  {
    if ($6 != "NO") {
        print ""
    } else if ($5 == "Syncing") {
        print "󰓦"
    } else if ($5 == "Synced") {
        print "󰄳"
    }
}'
