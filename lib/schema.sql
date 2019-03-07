CREATE TABLE wallpapers (
    filename text primary key
);

-- There is no restriction on having the same tag name multiple times.
CREATE TABLE tags (
    filename text references wallpapers(filename),
    name text,
    value text,
    UNIQUE (filename, name, value)
);

-- start/end x/y hold the pixels that define the original image in a generated
-- wallpaper
CREATE TABLE image_metadata (
    filename text references wallpapers(filename),
    startx int,
    starty int,
    endx int,
    endy int
);

-- By storing one or more fingerprints against an image before we create a
-- wallpaper, we can check input images for duplicates before we convert them to
-- wallpapers, instead of afterwards
CREATE TABLE image_fingerprint (
    filename text references wallpapers(filename),
    checksum text,
    fingerprint blob
);
