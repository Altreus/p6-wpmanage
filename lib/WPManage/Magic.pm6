unit package WPManage::Magic;

#| Returns the x/y of the top left of the smaller box so that it is in the
#| centre of the bigger box.
sub box-in-the-centre($big-w, $big-h, $small-w, $small-h) is export {
    my $x = ($big-w/2) - ($small-w/2);
    my $y = ($big-h/2) - ($small-h/2);

    return ($x.Int, $y.Int);
}

sub composite-in-the-middle($main-image, $overlay-image, $composite-type) is export {
    $main-image.composite($overlay-image, $composite-type,
        |box-in-the-centre($main-image.width, $main-image.height, $overlay-image.width, $overlay-image.height)
    );
}
