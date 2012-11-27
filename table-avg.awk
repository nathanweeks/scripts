#!/usr/bin/awk -f
# NAME
#     table-avg.awk - average each field from a list of input files
#
# SYNOPSIS
#     table-avg.awk FILE [FILE...]
#
# INPUT FILES
#     All input files are assumed to:
#     * be white-space delimited (i.e., no white-space within fields)
#     * have the same number of rows and columns
#     * have (the same) header line as the first line 
#     * have the same value in column 1 for a given line in the file
#     
# STDOUT
#     A table containing the averages of each field (>1) in each record (>1).
#
# EXAMPLES
#     $ cat file1.txt
#     Bin  TP  FP  FN  Precision
#     0-14.9   0   0   2   0.000
#     15-19.9  7   0   24  1.000
#     $ cat file2.txt
#     Bin  TP  FP  FN  Precision
#     0-14.9   0   0   1   0.000
#     15-19.9  5   0   22  1.000
#     $ cat file3.txt
#     Bin  TP  FP  FN  Precision
#     0-14.9   0   0   1   0.000
#     15-19.9  6   0   18  1.000
#     $ ./table-avg.awk file1.txt file2.txt file3.txt
#     Bin  TP  FP  FN  Precision
#     0-14.9  0   0   1.33333333333333    0
#     15-19.9 6   0   21.3333333333333    1
#     $ ./table-avg.awk OFMT="%.6g" file1.txt file2.txt file3.txt
#     Bin  TP  FP  FN  Precision
#     0-14.9  0   0   1.33333 0
#     15-19.9 6   0   21.3333 1
#
# CHANGE HISTORY
#    2012-10-29    Default OFMT to "%.15g" to display full precision.
#    2012-10-29    Initial version
#
# AUTHOR
#     Nathan Weeks <nathan.weeks@ars.usda.gov>

BEGIN { OFMT="%.15g" } # print all significant digits by default

# print header 
NR == 1

# record file names
FNR == 1 { filenames[FILENAME]; num_files++ }

# record each cell value
FNR > 1 {
    for (column = 1; column <= NF; column++)
        cell[FILENAME,FNR,column] = $column
}

END {
    for (row = 2; row <= FNR; row++) {
        # print 1st column
        printf("%s", cell[FILENAME,row,1])
        # for the remaining columns, print average across all input files
        for (column = 2; column <= NF; column++) {
            sum = 0.0
            for (filename in filenames)
                sum += cell[filename,row,column]
            printf("\t"OFMT, sum/num_files)
        }
        printf("\n")
    }
}
