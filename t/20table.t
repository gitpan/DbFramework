# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;
use t::Config;

BEGIN { 
  my %tests = ( mysql => 28, mSQL => 27 );
  my $tests;
  for ( @t::Config::drivers ) { $tests += $tests{$_} }
  plan tests => $tests;
}

require 't/util.pl';
use DbFramework::Attribute;
use DbFramework::Table;
use DbFramework::Util;
use DbFramework::DataModel;
use DbFramework::Catalog;

for ( @t::Config::drivers ) { foo($_) }

sub foo($) {
  my($driver) = @_;

  my $db  = 'dbframework_test';
  my $dsn = "DBI:$driver:database=$db";
  my $dm  = new DbFramework::DataModel($db,$dsn);
  my $dbh = $dm->dbh; $dbh->{PrintError} = 0;

  my $c = new DbFramework::Catalog("DBI:$driver:database=$DbFramework::Catalog::db");
  $dm->init_db_metadata;
  my $foo_table = $dm->collects_table_h_byname('foo');

  # as_string()
  my $ok_string;
  if ( $driver eq 'mysql' ) { # supports auto_increment
    $ok_string = <<EOF;
Table: foo
foo(INTEGER UNSIGNED (11) NOT NULL AUTO_INCREMENT)
bar(VARCHAR (10) NOT NULL)
baz(VARCHAR (10) NOT NULL)
quux(INTEGER UNSIGNED (11) NOT NULL)
foobar(TEXT (65535))
EOF
  } else {
    $ok_string = <<EOF;
Table: foo
foo(INT (4) NOT NULL)
bar(CHAR (10) NOT NULL)
baz(CHAR (10))
quux(INT (4))
foobar(TEXT (10))
EOF
}
  ok($foo_table->as_string,$ok_string);

  # as_html_form()
  $ok_string = <<EOF;
<tr><td><INPUT NAME="foo" VALUE="" SIZE=10 TYPE="text"></td></tr>
<tr><td><INPUT NAME="bar" VALUE="" SIZE=30 TYPE="text" MAXLENGTH=10></td></tr>
<tr><td><INPUT NAME="baz" VALUE="" SIZE=30 TYPE="text" MAXLENGTH=10></td></tr>
<tr><td><INPUT NAME="quux" VALUE="" SIZE=10 TYPE="text"></td></tr>
<tr><td><TEXTAREA COLS=60 NAME="foobar" ROWS=4></TEXTAREA></td></tr>
EOF
  ok($foo_table->as_html_form,$ok_string);

  # delete()
  $foo_table->delete;
  ok(1);

  # insert()
  my(@rows,$pk);
  for ('foo','bar','baz','quux') {
    push(@rows,{ foo => 0, bar => $_ });
  }
  for ( @rows ) { $pk = $foo_table->insert($_) }
  
  if ( $driver eq 'mysql' ) { # supports auto_increment
    ok($pk,$#rows + 1);
  } else {
    ok(1);
  }

  # select()
  my @lol = $foo_table->select(['foo']);
  ok(@lol,4);

  if ( $driver eq 'mysql' ) {
    # apply a function to a column in a 'SELECT...'
    my @loh = $foo_table->select_loh([q[lpad(foo,2,'0')]]);
    ok($loh[0]->{q[lpad(foo,2,'0')]},'01');
  }

  # mSQL doesn't return # rows modified
  my $rows = ( $driver eq 'mSQL' ) ? -1 : 2;
  ok($foo_table->delete(q{bar LIKE 'b%'}),$rows);

  # update()
  my $new_bar = 'bar';
  $rows = ( $driver eq 'mSQL' ) ? -1 : 1;
  ok($foo_table->update({bar => $new_bar },q{bar = 'foo'}),$rows);
  @lol = $foo_table->select(['bar'],undef,'bar');
  ok($lol[0]->[0],$new_bar);
  my @loh = $foo_table->select_loh(['bar'],undef,'bar');
  ok($loh[0]->{bar},$new_bar);

  # data model
  ok($dm->collects_table_h_byname('foo')->name,'foo');
  ok($dm->collects_table_h_byname('foo')->is_identified_by->as_sql,"PRIMARY KEY (foo,bar)");

  # foreign keys
  $foo_table = $dm->collects_table_h_byname('foo');
  ok($foo_table->is_identified_by->incorporates->name,'f_foo');
  my $bar_table = $dm->collects_table_h_byname('bar');
  ok($bar_table->has_foreign_keys_h_byname('f_foo')->name,'f_foo');

  my @fk = @{$bar_table->has_foreign_keys_l};
  my %fk = %{$bar_table->has_foreign_keys_h};
  my @keys = keys(%fk);
  ok(scalar(@fk),scalar(@keys));

  @fk = $dm->collects_table_h_byname('foo')->is_identified_by->incorporates;
  ok(scalar(@fk),scalar(@keys));
  ok($fk[0],$fk{f_foo});

  # keys
  ok($foo_table->in_key($foo_table->get_attributes('bar')),1);
  ok($foo_table->in_key($foo_table->get_attributes('foo')),0);

  # primary keys
  ok($foo_table->is_identified_by->belongs_to($foo_table),$foo_table);
  ok($foo_table->in_primary_key($foo_table->get_attributes('foo')),1);
  ok($foo_table->in_primary_key($foo_table->get_attributes('baz')),0);

  # foreign key
  my @fks = @{$bar_table->has_foreign_keys_l};
  ok(@fks,1);
  ok($bar_table->in_foreign_key($bar_table->get_attributes('foo_foo')),1);
  ok($bar_table->in_foreign_key($bar_table->get_attributes('foo')),0);

  # non-keys
  ok($foo_table->in_any_key($foo_table->get_attributes('foo')),1);
  ok($bar_table->in_any_key($bar_table->get_attributes('bar')),0);
  my @nka = $bar_table->non_key_attributes;
  ok($nka[0]->name,'bar');

  $dm->dbh->disconnect;
  $dbh->disconnect;
}
