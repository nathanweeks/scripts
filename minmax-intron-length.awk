#!/usr/bin/awk -f
# NAME
#     minmax-intron-length.awk - min & max intron lengths from CDS in GFF3 files
#
# SYNOPSIS
#     minmax-intron-length.awk [REPORT_CDS=1]
#                              [WARN_INTRON_LESS_THAN=min_intron_length]
#                              [WARN_INTRON_GREATER_THAN=max_intron_length]
#                              [GFF...]
#
# OPTIONS
#     REPORT_CDS
#         If set to 1, the CDS features flanking the smallest & largest
#         introns are output to stderr. The first detected flanking CDS
#         features for the given intron size are reported.
#
#     WARN_INTRON_LESS_THAN=min_intron_length
#         Issue a warning & print flanking CDSs to stderr if an intron smaller
#         than min_intron_length is detected. Does not affect the reported
#         minimum intron size.
#
#     WARN_INTRON_GREATER_THAN=max_intron_length
#         Issue a warning & print flanking CDSs to stderr if an intron longer
#         than max_intron_length is detected. Does not affect the reported
#         maximum intron size.
#
# OPERANDS
#     GFF
#         A GFF3 file containing at least mRNA and CDS features. Parent mRNA
#         features are assumed to appear in the file before any children CDS
#         features. "-" strand CDS features are assumed to be listed in
#         descending genomic order, while "+" strand CDS features are assumed
#         to be listed in ascending genomic order. Non-mRNA-or-CDS features
#         are ignored.
#     
# STDIN
#     Standard input will be used if no input file is specified, or if a file
#     is '-'.
#
# STDOUT
#     Two tab-separated integers:
#         MINIMUM_INTRON_LENGTH MAXIMUM_INTRON_LENGTH
#
# EXAMPLES
#     $ cat test.gff
#     ##gff-version 3
#     Gm03	Glyma1	gene	3629021	3632958	1	+	.	ID=Glyma03g03790;Name=Glyma03g03790
#     Gm03	Glyma1	mRNA	3629021	3632958	1	+	.	ID=Glyma03g03790.1;Name=Glyma03g03790.1;Parent=Glyma03g03790
#     Gm03	Glyma1	five_prime_utr	3629021	3629084	1	+	.	Parent=Glyma03g03790.1
#     Gm03	Glyma1	CDS	3629085	3629477	1	+	0	Parent=Glyma03g03790.1
#     Gm03	Glyma1	CDS	3630569	3630670	1	+	0	Parent=Glyma03g03790.1
#     Gm03	Glyma1	CDS	3630773	3630910	1	+	0	Parent=Glyma03g03790.1
#     Gm03	Glyma1	CDS	3631019	3631079	1	+	0	Parent=Glyma03g03790.1
#     Gm03	Glyma1	CDS	3632021	3632145	1	+	1	Parent=Glyma03g03790.1
#     Gm03	Glyma1	three_prime_utr	3632623	3632958	1	+	.	Parent=Glyma03g03790.1
#     Gm03	Glyma1	CDS	3632563	3632622	1	+	0	Parent=Glyma03g03790.1
#     Gm01	Glyma1	gene	8775304	8775489	0	-	.	ID=Glyma01g07880;Name=Glyma01g07880
#     Gm01	Glyma1	mRNA	8775304	8775489	0	-	.	ID=Glyma01g07880.1;Name=Glyma01g07880.1
#     Gm01	Glyma1	CDS	8775373	8775489	0	-	0	Parent=Glyma01g07880.1
#     Gm01	Glyma1	CDS	8775304	8775318	0	-	0	Parent=Glyma01g07880.1
#     $ minmax-intron-length.awk test.gff
#     54 1091
#
# CHANGE HISTORY
#     2013-02-05    Added the REPORT_CDS, WARN_INTRON_LESS_THAN, and
#                   WARN_INTRON_GREATER_THAN options.
#      
# AUTHOR
#     Nathan Weeks <nathan.weeks@ars.usda.gov>

BEGIN { 
    FS = OFS = "\t"
    max_intron_length = 0
    min_intron_length = 9999999999
}

/^#/ && NF != 9 { next } # skip blank lines & comment lines

$3 == "mRNA" { start = 0; end = 0 }

$3 == "CDS" {
    if ($7 == "-") {
        intron_length = (end ? end - $5 - 1 : 0)
        end = $4 # end <- start of this CDS
    } else {
        intron_length = (start ? $4 - start - 1 : 0)
        start = $5 # start <- end of this CDS
    }

    if (intron_length > 0 && intron_length < min_intron_length) {
        min_intron_length = intron_length
        min_intron_cds1 = prev_cds
        min_intron_cds2 = $0
    }
    if (intron_length > max_intron_length) {
        max_intron_length = intron_length
        max_intron_cds1 = prev_cds
        max_intron_cds2 = $0
    }

    if (intron_length > 0 && intron_length < WARN_INTRON_LESS_THAN) {
        print "intron length (" intron_length ") < WARN_INTRON_LESS_THAN (" \
              WARN_INTRON_LESS_THAN "):" | "cat 1>&2"
        print prev_cds | "cat 1>&2"
        print $0 | "cat 1>&2"
    }

    if (WARN_INTRON_GREATER_THAN && intron_length > WARN_INTRON_GREATER_THAN) {
        print "intron length (" intron_length ") > WARN_INTRON_GREATER_THAN (" \
              WARN_INTRON_GREATER_THAN "):" | "cat 1>&2"
        print prev_cds | "cat 1>&2"
        print $0 | "cat 1>&2"
    }

    prev_cds = $0
}


END { 
    print min_intron_length, max_intron_length
    if (REPORT_CDS) {
        print "min intron (" min_intron_length "):" | "cat 1>&2"
        print min_intron_cds1 | "cat 1>&2"
        print min_intron_cds2 | "cat 1>&2"
        print "max intron (" max_intron_length "):" | "cat 1>&2"
        print max_intron_cds1 | "cat 1>&2"
        print max_intron_cds2 | "cat 1>&2"
    }
}
