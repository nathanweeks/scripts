#!/usr/bin/awk -f
# NAME
#     fastq-q2-trim.awk - trim Q2 bases from Illumina 1.5+ FASTQ
#
# SYNOPSIS
#     fastq-q2-trim.awk TRIM_CHAR=[#|B] [MIN_LENGTH=N] [SUMMARY=[0|1]] [FILE...]
#
# DESCRIPTION
#     Trims the Q2 (read segment control indicator) bases from the final portion
#     of FASTQ reads.
#
# OPTIONS
#     MIN_LENGTH=N
#         Print sequences only with trimmed lengths >= N
#
#     SUMMARY
#         If set to "1", print total trimmed & untrimmed base pairs to
#         standard error.
#         
# OPERANDS
#     TRIM_CHAR=[#|B]
#         Specify:
#             "B" for phred+64 (ILLUMINA 1.5+)
#             "#" for phred+33 (ILLUMINA 1.8+).
#
#     FILE
#         A FASTQ file.
#
# STDIN
#     Standard input will be used if no file argument is given, or if a file
#     argument is '-'.
#
# STDOUT
#     Trimmed FASTQ 
#
# STDERR
#     If the SUMMARY option is set to "1", total trimmed & untrimmed base
#     pairs will be printed to standard error.
# 
# EXAMPLES
#     1. With MIN_LENGTH specified, reading from file operands
#
#       $ fastq-b-trim.awk TRIM_CHAR=# MIN_LENGTH=28 s1.fastq s2.fastq > trimmed.fastq
#
#     2. Without MIN_LENGTH, reading from stdin
#       
#       $ bzcat s1.fastq.bz2 s2.fastq.bz2 | fastq-b-trim.awk TRIM_CHAR=B > trimmed.fastq
#
# SEE ALSO
# 
#     Per "Using Genome Analyzer Sequencing Control Software Version 2.6"
#     (http://watson.nci.nih.gov/solexa/Using_SCSv2.6_15009921_A.pdf):
#
#         The read segment quality control metric identifies segments at the
#         end of reads that may have low quality, and unreliable quality
#         scores. If a read ends with a segment of mostly low quality (Q15 or
#         below), then all of the quality values in the segment are replaced
#         with a value of 2 (encoded as the letter B in Illumina's text-based
#         encoding of quality scores). We flag these regions specifically
#         because the initially assigned quality scores do not reliably
#         predict the true sequencing error rate. This Q2 indicator does not
#         predict a specific error rate, but rather indicates that a specific
#         final portion of the read should not be used in further analyses.
#
#      http://news.open-bio.org/news/2010/04/illumina-q2-trim-fastq/
#
# CHANGE HISTORY
#   2012-08-14    Added TRIM_CHAR option to handle Illumina 1.8+ sequences.
#   2012-07-21    Added SUMMARY option.
#   2011-08-03    Added MIN_LENGTH option.
#
# AUTHOR
#     Nathan Weeks <nathan.weeks@ars.usda.gov>

/^@/ {
    getline sequence
    getline seqid2
    getline qual

    untrimmed_bp += length(qual)
    untrimmed_reads++

    # for phred+33 sequences, skip the sequence if <is filtered> == "Y"
    if (TRIM_CHAR == "#" && $2 ~ /^[0-9]+:[0-9]+:[0-9]+:Y:/)
        next

    if (match(qual, TRIM_CHAR "+$")) {
        sequence = substr(sequence, 1, RSTART-1)
        qual = substr(qual, 1, RSTART-1)
    }

    if (length(sequence) >= MIN_LENGTH) {
        print $0 # seqid1
        print sequence
        print seqid2
        print qual
        trimmed_bp += length(sequence)
        trimmed_reads++
    }
}

END {
    if (SUMMARY) {
        print "untrimmed_reads:", untrimmed_reads | "cat 1>&2"
        print "untrimmed_bp:", untrimmed_bp | "cat 1>&2"
        print "trimmed_reads:", trimmed_reads | "cat 1>&2"
        print "trimmed_bp:", trimmed_bp | "cat 1>&2"
    }
}
