# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;

BEGIN { plan tests => 13}

use DbFramework::Table;
use DbFramework::Util;
use DbFramework::DataModel;

my($db,$table) = ('test','foo');

my $dbh = DbFramework::Util::get_dbh($db);
$dbh->{PrintError} = 0;
ok(1);

# create a test table
my $sql = qq{
  DROP TABLE $table
};
my $rc = $dbh->do($sql);
$sql = qq{
  CREATE TABLE $table($table int not null,
                   bar varchar(20),
		   baz int,
		   PRIMARY KEY($table))
};
$rc = $dbh->do($sql);

my $t = new DbFramework::Table($table,undef,undef,$dbh,{foo => 't/template'});

my $correct = q{<INPUT NAME="foo" VALUE="" SIZE=10 TYPE="text">
 <INPUT NAME="bar" VALUE="www.motorbase.com" SIZE=30 TYPE="text" MAXLENGTH=20>
 <INPUT NAME="baz" VALUE="1" SIZE=10 TYPE="text">
};
open(T,"<t/template") || die "Couldn't open t/template";
my @t = <T>;
ok($t->template_h_byname('foo'),"@t");

$t->init_db_metadata;
ok($t->template_h_byname('foo'),"@t");
ok($t->fill_template('foo'),$correct);

$correct = q{<INPUT NAME="bar" VALUE="www.motorbase.com" SIZE=30 TYPE="text" MAXLENGTH=20>};
ok($t->get_attributes('bar')->as_html_form_field('www.motorbase.com'),$correct);

package Foo;
use base qw(DbFramework::Persistent);

package main;

my $foo = new Foo($t->name,$t->dbh);
$foo->attributes_h(['foo','foo','bar',1,'baz',2]);
$foo->table->set_templates(foo => 't/template');
$correct = q{<INPUT NAME="foo" VALUE="foo" SIZE=10 TYPE="text">
 <INPUT NAME="bar" VALUE="1" SIZE=30 TYPE="text" MAXLENGTH=20>
 <INPUT NAME="baz" VALUE="2" SIZE=10 TYPE="text">
};
ok($foo->fill_template('foo'),$correct);

# default templates
$dbh = DbFramework::Util::get_dbh('music');
$t = new DbFramework::Table('artist',undef,undef,$dbh)->init_db_metadata;
my($pk_bg,$bg) = ($t->is_identified_by->bgcolor,$t->get_attributes('art_name')->bgcolor);
my $ok = qq{<TR>
<TD BGCOLOR='$pk_bg'><STRONG>art_id</STRONG></TD>
<TD><INPUT NAME="art_id" VALUE="" SIZE=10 TYPE="text"></TD>
</TR>
<TR>
<TD BGCOLOR='$bg'><STRONG>art_name</STRONG></TD>
<TD><INPUT NAME="art_name" VALUE="" SIZE=30 TYPE="text" MAXLENGTH=127></TD>
</TR>
};
ok($t->fill_template('input'),$ok);

my $dm = new DbFramework::DataModel('Music','music');

$t = $dm->collects_table_h_byname('release');
$ok = qq{<TR>
<TD BGCOLOR='#00ff00'><STRONG>rlse_id</STRONG></TD>
<TD><DbField release.rlse_id></TD>
</TR>
<TR>
<TD BGCOLOR='#ffffff'><STRONG>rlse_name</STRONG></TD>
<TD><DbField release.rlse_name></TD>
</TR>
<TR>
<TD BGCOLOR='#777777'><STRONG>label</STRONG></TD>
<TD><DbFKey release.label></TD>
</TR>
};
ok($t->template_h_byname('input'),$ok);

$t = new DbFramework::Table('artist',undef,undef,$dbh);
$t->init_db_metadata;
$ok = qq{<TR>
<TD BGCOLOR='$pk_bg'><STRONG>art_id</STRONG></TD>
<TD><DbField artist.art_id></TD>
</TR>
<TR>
<TD BGCOLOR='$bg'><STRONG>art_name</STRONG></TD>
<TD><DbField artist.art_name></TD>
</TR>
};
ok($t->template_h_byname('input'),$ok);

$ok = qq{<TR>
<TD BGCOLOR='$pk_bg'><STRONG>art_id</STRONG></TD>
<TD><INPUT NAME="art_id" VALUE="" SIZE=10 TYPE="text"></TD>
</TR>
<TR>
<TD BGCOLOR='$bg'><STRONG>art_name</STRONG></TD>
<TD><INPUT NAME="art_name" VALUE="" SIZE=30 TYPE="text" MAXLENGTH=127></TD>
</TR>
};
ok($t->fill_template('input'),$ok);
$t = $dm->collects_table_h_byname('artist');
ok($t->fill_template('input'),$ok);
$t = $dm->collects_table_h_byname('song');
my @fks = @{$t->is_accessed_using_l};
($pk_bg,$bg) = ($t->is_identified_by->bgcolor,$fks[0]->bgcolor);
$ok = qq{<TR>
<TD BGCOLOR='$pk_bg'><STRONG>song_id</STRONG></TD>
<TD><INPUT NAME="song_id" VALUE="" SIZE=10 TYPE="text"></TD>
</TR>
<TR>
<TD BGCOLOR='$bg'><STRONG>song_name</STRONG></TD>
<TD><INPUT NAME="song_name" VALUE="" SIZE=30 TYPE="text" MAXLENGTH=127></TD>
</TR>
};
ok($t->fill_template('input'),$ok);
$t = $dm->collects_table_h_byname('composition');
$bg = $t->is_identified_by->bgcolor;
$ok = qq{<TR>
<TD BGCOLOR='#777777'><STRONG>song</STRONG></TD>
<TD><SELECT NAME="song_id">
<OPTION  VALUE="1">1,Pigbag
</SELECT>
</TD>
</TR>
<TR>
<TD BGCOLOR='#777777'><STRONG>artist</STRONG></TD>
<TD><SELECT NAME="art_id">
</SELECT>
</TD>
</TR>
};
ok($t->fill_template('input'),$ok);

$dbh->disconnect;
