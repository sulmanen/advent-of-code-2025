# Solve strategy
Let JOLTAGE_SIZE be 12.

Recurse from the left picking always the largest digit found within the remove window, which decreases by one as digits are locked.

We need to have a data structure for output number of size 12.

We need to know the size of the remove window which starts with input.length - JOLTAGE_SIZE and decreases after each max digit has been found by the number of characters which have been skipped or removed which is the index of the current found digit minus the index of the previous found index plus one.

9__67 -> 3 - (0 + 1) = 2

## Paper run for 4 digits
number_string = 87653498860
initial remove_window = 11 - 4 = 7

### First iteration 
largest digit in the first seven characters in the string is 9 in index 6.

9___

remove_window = 7 - 6 = 1
current_index = 7

### Second iteration
If the remove window is 1 and the next digit is less than or equal to the current one, we keep the current one.

98__
remove_window = 1 - 7 - 7
current_index = 8

## Third iteration
Current digit is larger than the previous one so keep that.
988_

remove_window = 1 - 8 - 8 = 1
current_index = 9

## Fourth iteration
Current digit is larger than the next one. Keep the current one.

9886

Since the joltage digits are full, end the program and report the number
