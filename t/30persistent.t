# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;

BEGIN { plan tests => 15}

use DbFramework::Persistent;
use DbFramework::Table;
use DbFramework::Util;

package Song;
use base qw(DbFramework::Persistent);

package main;
my $db   = 'music';
my $dbh  = DbFramework::Util::get_dbh($db);
my $song = new Song('song',$dbh);
ok(1);

# init
$song->table->delete;
ok(1);

# insert
$song->attributes_h(['song_id',0,'song_name','Pigbag']);
ok($song->insert,1);
my %song = ( song_id => 0, song_name => 'Donna Lee' );
$song->attributes_h([ %song ]);
my $pk = $song->insert;
ok($pk,2);
my @a = $song->attributes_h_byname('song_id','song_name');
ok($a[1],$song{song_name});

# update
$song->attributes_h(['song_id',$pk,'song_name','Portrait Of Tracy']);
ok($song->update,1);

# select
$song->attributes_h([]);
my @songs = $song->select;
@a = $songs[0]->attributes_h_byname('song_id','song_name');
ok("@a",'1 Pigbag');
@a = $songs[1]->attributes_h_byname('song_id','song_name');
ok("@a",'2 Portrait Of Tracy');

@songs = $song->select(q{song_name like 'P%'});
ok(@songs,2);
@songs = $song->select(q{song_id = 2});
ok(@songs,1);
@a = $songs[0]->attributes_h_byname('song_id','song_name');
ok("@a",'2 Portrait Of Tracy');

# delete
ok($songs[0]->delete,1);

# make persistent (sub)class
my($class,$table) = ('Composition','composition');
my $ok = qq{package $class;
use strict;
use base qw(DbFramework::Persistent);
};
ok(DbFramework::Persistent->make_class($class),$ok);
eval $ok;
my $composition = new Composition('composition',$dbh);
ok($composition->table->name,$table);

# html form
%song = ( song_id => 0, song_name => 'Donna Lee' );
$song->attributes_h([ %song ]);
$ok = qq{<TR><TD><STRONG>song_id</STRONG></TD><TD><INPUT NAME="song_id" VALUE="0" SIZE=10 TYPE="text"></TD></TR>
<TR><TD><STRONG>song_name</STRONG></TD><TD><INPUT NAME="song_name" VALUE="Donna Lee" SIZE=30 TYPE="text" MAXLENGTH=127></TD></TR>
};
ok($song->as_html_form,$ok);

$dbh->disconnect;
