# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;
use t::Config;

BEGIN { plan tests => scalar(@t::Config::drivers) * 5 }

require 't/util.pl';
use DbFramework::Catalog;
use DbFramework::Util;
use DbFramework::DataModel;
use DbFramework::Table;

my($t1,$t2);

if ( grep(/mysql/,@t::Config::drivers) ) { 
  $t1 = qq{CREATE TABLE foo (foo integer not null auto_increment,
			     bar varchar(10) not null,
			     baz varchar(10) not null,
			     quux integer not null,
			     foobar text,
			     KEY foo(bar,baz),
			     KEY bar(baz,quux),
			     PRIMARY KEY (foo,bar)
			    )};
  $t2 = qq{CREATE TABLE bar (foo integer not null auto_increment,
			     # foreign key (foo)
			     foo_foo integer not null,
			     foo_bar varchar(10) not null,
			     bar integer,
			     KEY f_foo(foo_foo,foo_bar),
			     PRIMARY KEY (foo)
			    )};
  foo('mysql','foo',$t1,'bar',$t2);
}

if ( grep(/mSQL/,@t::Config::drivers) ) {
  $t1 = qq{CREATE TABLE foo (foo integer not null,
			     bar char(10) not null,
			     baz char(10),
			     quux integer,
			     foobar text(10)
			    )};
  $t2 = qq{CREATE TABLE bar (foo integer not null,
			     # foreign key (foo)
			     foo_foo integer,
			     foo_bar char(10),
			     bar integer
			    )};
  foo('mSQL','foo',$t1,'bar',$t2);
}

sub foo($$$$$) {
  my($driver,$t1,$t1_sql,$t2,$t2_sql) = @_;
  my $c = new DbFramework::Catalog("DBI:$driver:database=$DbFramework::Catalog::db");
  ok(1);

  my $db  = 'dbframework_test';
  my $dsn = "DBI:$driver:database=$db";
  my $dm  = new DbFramework::DataModel($db,$dsn);
  my $dbh = $dm->dbh; $dbh->{PrintError} = 0;

  $dm->init_db_metadata;

  # test primary keys
  my $foo_table = $dm->collects_table_h_byname('foo');
  ok($foo_table->is_identified_by->as_sql,'PRIMARY KEY (foo,bar)');

  # test keys
  my @keys = @{$foo_table->is_accessed_using_l};
  ok($keys[0]->as_sql,'KEY bar (baz,quux)');
  ok($keys[1]->as_sql,'KEY foo (bar,baz)');

  # test foreign keys
  my $bar_table = $dm->collects_table_h_byname('bar');
  my $fk = $bar_table->has_foreign_keys_h_byname('f_foo');
  ok($fk->as_sql,'KEY f_foo (foo_foo,foo_bar)');

  $dbh->disconnect;
}
