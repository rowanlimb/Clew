#! /usr/bin/env python

import sys

# -- Zoo Data
# animal name:  Unique for each instance
# hair		Boolean
# feathers	Boolean
# eggs		Boolean
# milk		Boolean
# airborne	Boolean
# aquatic	Boolean
# predator	Boolean
# toothed	Boolean
# backbone	Boolean
# breathes	Boolean
# venomous	Boolean
# fins		Boolean
# legs		Numeric (set of values: {0,2,4,5,6,8})
# tail		Boolean
# domestic	Boolean
# catsize	Boolean
# type		Numeric (integer values in range [1,7])

for line in sys.stdin:
    line = line.strip()
    unpacked = line.split(",")
    animal,hair,feathers,eggs,milk,airborne,aquatic,predator,toothed,backbone,breathes,venomous,fins,legs,tail,domestic,catsize,type = line.split(",")
    results = [feathers, "1"]
    print("\t".join(results))


