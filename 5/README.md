# Day: 5

## Strategy
Find number of unique freshIds. We start with n ranges which partially overlap and there may be duplicates. The solution is to flatten the ranges and then count the unique freshIds.

## Flattening Strategy
Take first range. Find all overlapping ranges, start is the min of all of these ranges and the end is the max of all these ranges. Remove all overlapping ranges from the list. Add flattened range to the list.
