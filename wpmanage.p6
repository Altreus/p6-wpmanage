use WPManage;

sub MAIN ($ar is copy, Str $fn) {
    my $wp = wp(:$fn, :output-dir('output'));

    if $ar ~~ /x/ {
        my ($w, $h) = $ar.split('x');
        $wp.overlay-on-background($w.Int, $h.Int);
    }
    else {
        $wp.overlay-on-background($ar.Rat);
    }

    $wp.write;
}
