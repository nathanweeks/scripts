#!/usr/bin/awk -f
# NAME
#     intron-length.awk - report intron lengths from GFF3 input
#
# SYNOPSIS
#     intron-length.awk [TYPE=CDS|exon]
#                       [SHOW_FLANKING=1]
#                       [WARN_INTRON_LESS_THAN=min_intron_length]
#                       [WARN_INTRON_GREATER_THAN=max_intron_length]
#                       [GFF...]
#
# DESCRIPTION
#     Reports the minimum intron length, maximum intron length, and the
#     maximum sum-of-intron-lengths among all mRNA features. Intron lengths
#     are calculated from gaps between features of type TYPE.
#
# OPTIONS
#     TYPE
#         GFF3 type (3rd-column); valid values are "CDS" and "exon" (default).
#         Introns are calculated as gaps between features if this type.
#
#     SHOW_FLANKING
#         If set to 1, the features of type TYPE flanking the smallest &
#         largest introns are output to stderr. The first detected flanking
#         features for the given intron size are reported.
#
#     WARN_INTRON_LESS_THAN=min_intron_length
#         Issue a warning & print flanking features to stderr if an intron
#         smaller than min_intron_length is detected. Does not affect the
#         reported minimum intron size.
#
#     WARN_INTRON_GREATER_THAN=max_intron_length
#         Issue a warning & print flanking features to stderr if an intron
#         longer than max_intron_length is detected. Does not affect the
#         reported maximum intron size.
#
# OPERANDS
#     GFF
#         A GFF3 file containing at least mRNA and CDS or exon features.
#         Parent mRNA features are assumed to appear in the file before any
#         children CDS/exon features. "-" strand CDS/exon features are assumed
#         to be listed in descending genomic order, while "+" strand CDS/exon
#         features are assumed to be listed in ascending genomic order.
#         Features not of type "mRNA" or the user-specified TYPE (assumed to
#         be "CDS" or "exon") are ignored.
#     
# STDIN
#     Standard input will be used if no input file is specified, or if a file
#     is '-'.
#
# STDOUT
#     Three tab-separated integers:
#         MINIMUM_INTRON_LENGTH MAXIMUM_INTRON_LENGTH MAXIMUM_SUM_INTRON_LENGTHS
#
# APPLICATION USAGE
#     The output can be used to supply values to the the gmap
#     --min-intronlength, --intronlength, and --totallength options.
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
#     $ intron-length.awk TYPE=CDS test.gff
#     54	1091	2659
#
# FUTURE DIRECTIONS
#     five_prime_utr/three_prime_utr features will likely be supported in the
#     future for TYPE=CDS.
#
# SEE ALSO
#     GMAP (http://research-pub.gene.com/gmap/)
#
# CHANGE HISTORY
#     2014-10-29    Handle gene features without mRNA subfeatures.
#     2013-04-11    Renamed option REPORT_FLANKING to SHOW_FLANKING.
#     2013-04-10    Report the largest sum-of-intron-lengths seen for any
#                   mRNA feature.
#                   Added TYPE option.
#                   REPORT_CDS option renamed to SHOW_FLANKING.
#     2013-02-05    Added the REPORT_CDS, WARN_INTRON_LESS_THAN, and
#                   WARN_INTRON_GREATER_THAN options.
#
# AUTHOR
#     Nathan Weeks <nathan.weeks@ars.usda.gov>

BEGIN { 
    FS = OFS = "\t"
    stderr = "cat 1>&2"
    max_intron_length = 0
    min_intron_length = 9999999999
}

/^#/ || NF == 0 { next } # comments, pragmas, and blank lines

$3 == "mRNA" || $3 == "gene" { start = end = total_intron_length = 0 }

TYPE ? $3 == TYPE : $3 == "exon" {
    if ($7 == "-") {
        intron_length = (end ? end - $5 - 1 : 0)
        end = $4 # end <- start of this feature
    } else {
        intron_length = (start ? $4 - start - 1 : 0)
        start = $5 # start <- end of this feature
    }

    total_intron_length += intron_length

    if (total_intron_length > max_sum_intron_lengths)
        max_sum_intron_lengths = total_intron_length

    if (intron_length > 0 && intron_length < min_intron_length) {
        min_intron_length = intron_length
        min_intron_feature1 = prev_feature
        min_intron_feature2 = $0
    }
    if (intron_length > max_intron_length) {
        max_intron_length = intron_length
        max_intron_feature1 = prev_feature
        max_intron_feature2 = $0
    }

    if (intron_length > 0 && intron_length < WARN_INTRON_LESS_THAN) {
        print "intron length (" intron_length ") < WARN_INTRON_LESS_THAN (" \
              WARN_INTRON_LESS_THAN "):" | stderr
        print prev_feature | stderr
        print $0 | stderr
    }

    if (WARN_INTRON_GREATER_THAN && intron_length > WARN_INTRON_GREATER_THAN) {
        print "intron length (" intron_length ") > WARN_INTRON_GREATER_THAN (" \
              WARN_INTRON_GREATER_THAN "):" | stderr
        print prev_feature | stderr
        print $0 | stderr
    }

    prev_feature = $0
}


END { 
    print min_intron_length, max_intron_length, max_sum_intron_lengths
    if (SHOW_FLANKING) {
        print "min intron (" min_intron_length "):" | stderr
        print min_intron_feature1 | stderr
        print min_intron_feature2 | stderr
        print "max intron (" max_intron_length "):" | stderr
        print max_intron_feature1 | stderr
        print max_intron_feature2 | stderr
    }
}
