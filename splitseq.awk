#!/usr/bin/awk -f
# NAME
#     splitseq.awk - split a FASTA sequence into N non-overlapping subsequences
#
# SYNOPSIS
#     splitseq.awk N=NUM_SUBSEQUENCES FASTA_FILE
#
# DESCRIPTION
#     Splits the sequence in FASTA_FILE into NUM_SUBSEQUENCES non-overlapping
#     subsequences.
#
# OPTIONS
#     N=NUM_SUBSEQUENCES
#         (required) Number of non-overlapping subsequences
#
# OPERANDS
#     FASTA_FILE
#         FASTA file containing a single sequence.
#          
# STDIN
#     Standard input will be used if a file operand is '-'.
#
# OUTPUT FILES
#     NUM_SUBSEQUENCES FASTA files, each containing sequences of the same
#     length, except the last file may be shorter. Files will be named
#     SEQID:START..END.fa, where seqid is obtained from the sequence in
#     FASTA_FILE, and START and END represent the range of the subsequence in
#     the file. Each file will contain two lines (the entire subsequence will
#     be printed on one line).
#     
# EXAMPLES
#   $ cat test.fa
#   >myseq1
#   TTACATCAATAATGATTCTCAAATCTCAACCAAATGAACT
#   CATTAGTGTAAAGCTCATTTTAGGTAAACCTTTTGAAAAA
#   GTTCCTTGTGTAGCATGACCAAAATATATATTCATGTTAA
#   AGAAAGGCCTAAACCCTGACCGAGAAAGCACATTTTCTTA
#   GGACAATTTCATACAATTGTTGTTCACATTAAATTTGTTT
#   TAACACTACAAGGTCTTGTAAGAACTTCACATGATGATGT
#   CATTAATCTCTTTCTTGTTTTTTAAAGTTGAATAAAAACG
#   TGTTTTTGCCTAAATCTTTGACCTTTACTTCTTTCTTTAT
#   $ splitseq.awk N=5 test.fa
#   $ ls myseq*.fa
#   myseq1:1..64.fa
#   myseq1:129..192.fa
#   myseq1:193..256.fa
#   myseq1:257..320.fa
#   myseq1:65..128.fa
#   $ cat myseq1:1..64.fa   
#   >myseq1:65..128
#   TAAACCTTTTGAAAAAGTTCCTTGTGTAGCATGACCAAAATATATATTCATGTTAAAGAAAGGC
#
# AUTHOR
#     Nathan Weeks <nathan.weeks@ars.usda.gov>

/^>/ { seqid = substr($1, 2) }
/^[^>]/ { seq = seq $0 }

END {
    seq_length = length(seq)
    subseq_length = int((seq_length+N-1)/N) # round up
    for (subseq_start = 1; subseq_start <= length(seq); 
         subseq_start += subseq_length)
    {
        subseq_end = (subseq_start + subseq_length - 1 < seq_length) ? \
                     subseq_start + subseq_length - 1 : seq_length
        subseq_seqid = seqid ":" subseq_start ".." subseq_end
        subseq_file = subseq_seqid ".fa"
        printf(">%s\n%s\n", subseq_seqid, 
               substr(seq, subseq_start, subseq_length)) \
               > subseq_file
        close(subseq_file)
    }
}
