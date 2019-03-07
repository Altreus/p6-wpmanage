use MagickWand;
use MagickWand::Enums;
use MagickWand::NativeCall::Wand;
use WPManage::Magic;

unit class WPManage::Wallpaper;

has $.fn;
has $.output-dir;
has $.dbh;
has $!mw;
has %img-pos;

submethod DESTROY {
    .cleanup with $!mw;
}

#| Set the points defining the top-left and bottom-right of the original image
#| inside the wallpaper as hashes with x and y keys.
method set-original-coords(:%top-left, :%bottom-right) {
    $.dbh
}

method magick-wand {
    .return with $!mw;

    say $.fn;
    $!mw = MagickWand.new;
    unless $!mw.read($.fn) {
        die "Failed to read $.fn";
    }
    $!mw;
}

method width {
    self.magick-wand.width
}

method height {
    self.magick-wand.height
}

method aspect-ratio {
    self.magick-wand.width / self.magick-wand.height;
}

method write {
    say $.output-dir ~ '/' ~ $.fn.IO.basename;
    self.magick-wand.write($.output-dir ~ '/' ~ $.fn.IO.basename);
}

#| Makes this wallpaper's aspect ratio $ar by scaling up the image and blurring
#| it, then darkening it, and finally superposing the original image smack in
#| the middle.
multi method overlay-on-background(Rat $ar) {
    return if self.aspect-ratio == $ar;

    my $shadow-size = (0.008 * self.smaller-dimension($ar)).Int;
    my $bg = self.create-shade(|self.new-dimensions($ar));
    # Put blurry background image and darkening layer together. bg is smaller so
    # has to be the main image here (bg is the target size!)
    my $shadow = self.create-drop-shadow(10);
    composite-in-the-middle($bg, self.scaled-up($ar), DstOverCompositeOp);
    composite-in-the-middle($shadow, $!mw, SrcOverCompositeOp);
    composite-in-the-middle($bg, $shadow, SrcOverCompositeOp);
    $!mw = $bg;
}

multi method overlay-on-background(Int $w, Int $h) {
    return self.overlay-on-background($w/$h);
}

method new-dimensions($ar) {
    # This is the size the image will be if we make self into $ar
    my $new-w = self.width;
    my $new-h = self.height;

    my $sf = self.scale-factor($ar);
    if self.taller-or-wider($ar) eq 'taller' {
        $new-w *= $sf;
    }
    else {
        $new-h *= $sf;
    }

    return ($new-w.Int, $new-h.Int);
}

method create-shade($w, $h) {
    my $img = MagickWand.new;
    $img.create($w, $h, "#00000070");
    return $img;
}

# Returns a shadow around the whole image. Crop it yourself.
method create-drop-shadow($size) {
    # Don't seem to have access to draw rectangle, so I'm making two images
    # instead.
    # TODO: Use alpha channel from source image to create black shape first
    my $drop-shadow = MagickWand.new;
    $drop-shadow.create(self.width, self.height, "#000000");

    my $drop-shadow-bg = MagickWand.new;
    $drop-shadow-bg.create(self.width + $size*2, self.height + $size*2, "#00000000");
    $drop-shadow-bg.composite(
        $drop-shadow, OverlayCompositeOp, $size, $size
    );
    $drop-shadow-bg.gaussian-blur(0, $size);

    return $drop-shadow-bg;
}

method scaled-up($ar) {
    my $scaled-up = self.magick-wand.clone;
    say "Resizing by {self.scale-factor($ar)}";
    $scaled-up.resize(self.scale-factor($ar));
    $scaled-up.gaussian-blur(0, 12);

    say "created scale up {$scaled-up.width}, {$scaled-up.height}";
    return $scaled-up;
}

method scale-factor($ar) {
    # e.g.:
    # Tall; we widen
    # self.ar == 0.25 (1:4)
    # $ar == 1.4
    # scale factor = 1.4/0.25 == 5.6
    #
    # Wide; we tallen
    # self.ar == 4 (4:1)
    # $ar == 1.4
    # scale factor = 4/1.4 == 2.8571
    #

    with self.taller-or-wider($ar) {
        return $_ eq 'taller'
            ?? $ar / self.aspect-ratio
            !! self.aspect-ratio / $ar;
    }
    return 1;
}

#| We return undefined if neither.
method taller-or-wider($ar) {
    # OK. An AR > 1 is wide, and an AR < 1 is tall. So if our AR is less than
    # the requested AR, then we are taller than required; otherwise we are wider
    # than required. We decide which dimension has to be increased and divide
    # appropriately.
    return 'taller' if self.aspect-ratio < $ar;
    return 'wider' if self.aspect-ratio > $ar;
    return
}

method smaller-dimension($ar) {
    return self.taller-or-wider($ar) eq 'taller'
        ?? self.width
        !! self.height;
}
