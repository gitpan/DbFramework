# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;

BEGIN { plan tests => 42}

use DbFramework::Attribute;
use DbFramework::Table;
use DbFramework::DataType;
use DbFramework::Util;
use DbFramework::DataModel;

my $dbh        = DbFramework::Util::get_dbh('music');
$dbh->{PrintError} = 0;
my $a1_sql     = q{song_id INT(11) NOT NULL AUTO_INCREMENT};
my $a2_sql     = q{song_name VARCHAR(127) NOT NULL DEFAULT 'Song With No Name'};

my $create_sql = qq{CREATE TABLE artist (
  art_id int(11) DEFAULT '0' NOT NULL AUTO_INCREMENT,
  art_name varchar(127),
  PRIMARY KEY (art_id)
)};
drop_create('artist',$create_sql);
my $composition_sql = qq{CREATE TABLE composition (
  art_id int(11) DEFAULT '0' NOT NULL,
  song_id int(11) DEFAULT '0' NOT NULL,
  PRIMARY KEY (art_id,song_id),
  KEY f_artist (art_id),
  KEY f_song (song_id)
)};
drop_create('composition',$composition_sql);
$create_sql = qq{CREATE TABLE label (
	lbl_id int(11) not null auto_increment,
	lbl_name varchar(127) not null,
	PRIMARY KEY (lbl_id),
	KEY lbl_name (lbl_name)
)};
drop_create('label',$create_sql);
$create_sql = qq{CREATE TABLE release (
	rlse_id int(11) not null auto_increment,
	rlse_name varchar(127) not null,
        lbl_id int(11) not null,
	PRIMARY KEY (rlse_id),
        KEY f_label (lbl_id),
	KEY lbl_name (rlse_name)
)};
drop_create('release',$create_sql);
$create_sql = qq{CREATE TABLE song (
	$a1_sql,
	$a2_sql,
	PRIMARY KEY (song_id),
	KEY song_name (song_name)
)};
drop_create('song',$create_sql);

# invalid data type
my $bad = eval { new DbFramework::DataType('foo',0,undef) };
$@ =~ s/\nValid.*$//s;
ok($@,"Invalid datatype 'FOO'");

# attributes
my $a1 = new DbFramework::Attribute('song_id',0,0,
				    new DbFramework::DataType('int',
							      11,
							      'auto_increment'
							     )
				   );

ok($a1->as_sql($dbh),$a1_sql);

my $a2 = new DbFramework::Attribute('song_name','Song With No Name',0,
				    new DbFramework::DataType('varchar',
							      127,
							      undef
							     )
				   );
ok($a2->as_sql($dbh),$a2_sql);

my $pk = new DbFramework::PrimaryKey([$a1]);
ok($pk->incorporates_l->[0]->name,$a1->name);

# table
my $t = new DbFramework::Table('song',[ $a1,$a2 ],$pk,$dbh);
ok($t->name,'song');
ok($t->contains_l->[0],$a1);
ok($t->contains_l->[1],$a2);
ok($t->get_attributes,2);

my @a_names = $t->get_attribute_names;
ok("@a_names","song_id song_name");
my $text = <<EOF;
Table: song
song_id(INT (11) NOT NULL AUTO_INCREMENT)
song_name(VARCHAR (127) 'Song With No Name' NOT NULL)
EOF
ok($t->as_string,$text);

$text = <<EOF;
Table: song
song_id(INT (11) NOT NULL AUTO_INCREMENT)
song_name(VARCHAR (127) 'Song With No Name' NOT NULL)
EOF
my $t2 = new DbFramework::Table('song',undef,undef,$dbh);
$t2->init_db_metadata;
ok($t2->as_string,$text);
ok($t2->as_sql,$create_sql);

# table as html
$text = <<EOF;
<INPUT NAME="song_id" VALUE="" SIZE=10 TYPE="text">
<INPUT NAME="song_name" VALUE="" SIZE=30 TYPE="text" MAXLENGTH=127>
EOF
ok($t->as_html_form,$text);
ok($t2->as_html_form,$text);

# SQL ops on a table
$t2->delete;
ok(1);
my @songs;
for ('Relax','Rio','Really Free','JuJu') {
  push(@songs,{ song_id => 0, song_name => $_ });
}
for ( @songs ) { $pk = $t2->insert($_) }
ok($pk,$#songs + 1);
my @lol = $t2->select(['song_id']);
ok(@lol,4);
ok($t2->delete(q{song_name like 'R%'}),3);
my $new_song = 'Speak No Evil';
ok($t2->update({song_name => $new_song },q{song_name = 'JuJu'}),1);
@lol = $t2->select(['song_name']);
ok($lol[0]->[0],$new_song);

# data model
my $dm = new DbFramework::DataModel('Music','music');

ok($dm->collects_table_h_byname('song')->as_html_form('foo.cgi'),$text);

ok($dm->collects_table_h_byname('composition')->is_identified_by->as_sql,"PRIMARY KEY (art_id,song_id)");

# foreign keys
$t = $dm->collects_table_h_byname('label');
ok($t->is_identified_by->incorporates->name,'label');
$t = $dm->collects_table_h_byname('song');
ok($t->is_identified_by->incorporates->name,'song');
$t = $dm->collects_table_h_byname('artist');
ok($t->is_identified_by->incorporates->name,'artist');

$t = $dm->collects_table_h_byname('composition');
ok($t->has_foreign_keys_h_byname('song')->name,'song');
ok($t->has_foreign_keys_h_byname('artist')->name,'artist');

$t = $dm->collects_table_h_byname('release');

my @fk = @{$t->has_foreign_keys_l};
my %fk = %{$t->has_foreign_keys_h};
my @keys = keys(%fk);
ok(scalar(@fk),scalar(@keys));
@fk = $dm->collects_table_h_byname('label')->is_identified_by->incorporates;
ok(scalar(@fk),scalar(@keys));
ok($fk[0],$fk{'label'});

$t = $dm->collects_table_h_byname('song');

# key
ok($t->in_key($t->get_attributes('song_name')),1);
ok($t->in_key($t->get_attributes('song_id')),0);

# primary key
ok($t->is_identified_by->belongs_to($t),$t);
ok($t->in_primary_key($t->get_attributes('song_id')),1);
ok($t->in_primary_key($t->get_attributes('song_name')),0);

# foreign key
$t = $dm->collects_table_h_byname('composition');
my @fks = @{$t->has_foreign_keys_l};
ok(@fks,2);
ok($t->in_foreign_key($t->get_attributes('song_id')),1);
$t = $dm->collects_table_h_byname('song');
ok($t->in_foreign_key($t->get_attributes('song_name')),0);
$t = $dm->collects_table_h_byname('release');
ok($t->in_foreign_key($t->get_attributes('lbl_id')),1);

# non-key
$t = $dm->collects_table_h_byname('artist');
ok($t->in_any_key($t->get_attributes('art_id')),1);
ok($t->in_any_key($t->get_attributes('art_name')),0);
my @nka = $t->non_key_attributes;
ok($nka[0]->name,'art_name');


$dm->dbh->disconnect;
$dbh->disconnect;

sub drop_create {
  my($table,$sql) = @_;
  my $rv = $dbh->do("DROP TABLE $table");
  return $dbh->do($sql) || die $dbh->errstr;
}
