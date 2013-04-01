#!/usr/bin/awk -f
# NAME
#     seqlen.awk - Print length of sequences from FASTA input
#
# SYNOPSIS
#     seqlen.awk [fasta_file...]
#
# DESCRIPTION
#     Generates sequence ID, sequence length pairs from FASTA input.
#
# OPERANDS
#     fasta_file
#         A FASTA file containing one or more sequences.
#
# STDIN
#     Standard input will be used if no input file is specified, or if a file
#     is '-'.
#         
# STDOUT
#     One line per input sequence, containing two tab-separated fields:
#     <sequence_id>	<length>
#
# EXAMPLES
#     $ cat fosmid.fa
#     >lcl|FFOF1000 3432432 FFOF
#     ACTG
#     >lcl|FFOF1001 3432433 FFOF
#     >lcl|FFOF1002 3432434 FFOF
#     ACTG
#     ACTG
#     $ seqlen.awk fosmid.fa
#     lcl|FFOF1000	4
#     lcl|FFOF1001	0
#     lcl|FFOF1002	8
#
# SEE ALSO
#     NCBI's description of the FASTA format:
#         http://www.ncbi.nlm.nih.gov/BLAST/blastcgihelp.shtml
#
# AUTHOR
#     Nathan Weeks <nathan.weeks@ars.usda.gov>

BEGIN { OFS="\t" }
/^>/ { 
    # Print results for any previous sequence
    if (sequence_id)
        print sequence_id, sequence_length

    # Initialize seqid & seqlen for new sequence
    sequence_id  = substr($1, 2)
    sequence_length = 0
}

/^[^>]/ { sequence_length += length($0) }

# Print results for last sequence
END { print sequence_id, sequence_length }
