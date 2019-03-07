use File::Path::Resolve;
use DBIish;
use WPManage::Wallpaper;

unit package WPManage;

sub dbh {
    my $sqlite-file = %*ENV<WPMANAGE_DB_FILE> || %*ENV<HOME> ~ '/.local/wpmanage.sqlite3';
    state $dbh = DBIish.connect("SQLite", database => $sqlite-file, :RaiseError);
}

sub wp(:$fn, :$output-dir) is export {
    my $fn-full = ~File::Path::Resolve.relative($fn, ~$*CWD);
    WPManage::Wallpaper.new(:fn($fn-full), :$output-dir, :dbh(dbh()));
}
