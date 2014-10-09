#!/usr/bin/perl -pie

# Pass along classes defined in {} to the li.  Set LI class to .fragment to create incremental
s/<li>\s*{(.*?)}//gimx && do {
    my @classes = split(/[\.\s]+/,$1);
    print '<li class="'.join(" ",@classes).'">';
};

# make an entire list list incremental.
#s/class="incremental"/class="fragment"/gimx;

# ----- ABANDONED 
# footnotes to presenter notes 
# scrub footnote superscripts
#s/<sup><a\ href=.*?footnoteRef.*?<\/sup>//gmx;
# change footnote section to <aside class="notes">
#s/<section\ class=\"footnotes\">.*?<hr\ \/>(.*?)<\/section>/<aside class="notes">$1<\/aside>/gmxs;

# pandoc has already turned everything into html, 
# so this converst the special markdown syntax ::{Topic}::
# by scrubbint the colons and changing to a special 
# <h1> topic class for single line topic pages
# <h1 class="topic">{Topic}</h1>
s/<h1>::(.*?)::<\/h1>/<h1 class="topic">$1<\/h1>/gimx;
