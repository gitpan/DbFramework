# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test;
use DBI 1.06;
use DbFramework::Util;
use DbFramework::Catalog;
use t::Config;
require "t/util.pl";

BEGIN { 
  my $tests = 1;
  for ( values %t::Config::catalog_db ) { $tests += $_ }
  plan tests => $tests + scalar(@t::Config::drivers) * 2;
}

# create databases
my $test_db    = 'dbframework_test';
my $catalog_db = 'dbframework_catalog';
my %sql        = %{catalog_schema()};
for my $driver ( @t::Config::drivers ) {
  my $drh = DBI->install_driver($driver);
  my $rc  = $drh->func("createdb", $test_db, 'admin');
  ok(1);
  $rc     = $drh->func("createdb", $catalog_db, 'admin');
  ok(1);
  if ( $t::Config::catalog_db{$driver} ) {
    # create catalog schema
    my $dbh = DbFramework::Util::get_dbh("DBI:$driver:database=$catalog_db");
    $dbh->{PrintError} = 0;
    for my $table ( qw/c_db c_key c_relationship c_table/ ) {
      drop_create($catalog_db,$table,undef,$sql{$driver}->{$table},$dbh);
    }
    ok(1);

    my($t1,$t2) = ('foo','bar');

    ## set db
    my $sql = qq{
      INSERT INTO c_db
      VALUES('$test_db')};
    my $sth = do_sql($dbh,$sql);  $sth->finish;

    ## set tables
    $sql = qq{
      INSERT INTO c_table
      VALUES('$t1','$test_db')};
    $sth = do_sql($dbh,$sql);  $sth->finish;
    $sql = qq{
      INSERT INTO c_table
      VALUES('$t2','$test_db')};
    $sth = do_sql($dbh,$sql);  $sth->finish;

    ## set primary keys
    $sql = qq{
      INSERT INTO c_key
      VALUES('$test_db','$t1','primary',$DbFramework::Catalog::keytypes{primary},'foo:bar')};
    $sth = do_sql($dbh,$sql);  $sth->finish;
    $sql = qq{
      INSERT INTO c_key
      VALUES('$test_db','$t2','primary',$DbFramework::Catalog::keytypes{primary},'foo')};
    $sth = do_sql($dbh,$sql);  $sth->finish;

    ## set keys (indexes)
    $sql = qq{
      INSERT INTO c_key
      VALUES('$test_db','$t1','foo',$DbFramework::Catalog::keytypes{index},'bar:baz')};
    $sth = do_sql($dbh,$sql);  $sth->finish;
    $sql = qq{
      INSERT INTO c_key
      VALUES('$test_db','$t1','bar',$DbFramework::Catalog::keytypes{index},'baz:quux')};
    $sth = do_sql($dbh,$sql);  $sth->finish;

    ## set foreign keys
    $sql = qq{
      INSERT INTO c_key
      VALUES('$test_db','$t2','f_foo',$DbFramework::Catalog::keytypes{foreign},'foo_foo:foo_bar')};
    $sth = do_sql($dbh,$sql);  $sth->finish;
    $sql = qq{
      INSERT INTO c_relationship
      VALUES('$test_db','$t2','f_foo','$t1')
  };
    $sth = do_sql($dbh,$sql);  $sth->finish;
    $dbh->disconnect;
  }
}

sub catalog_schema {
  return { mysql => { c_db => q{
CREATE TABLE c_db (
		   db_name varchar(50) DEFAULT '' NOT NULL,
		   PRIMARY KEY (db_name)
		  )
},
		      c_key => q{
CREATE TABLE c_key (
		    db_name varchar(50) DEFAULT '' NOT NULL,
		    table_name varchar(50) DEFAULT '' NOT NULL,
		    key_name varchar(50) DEFAULT '' NOT NULL,
		    key_type int(11) DEFAULT '0' NOT NULL,
		    key_columns varchar(255) DEFAULT '' NOT NULL,
		    PRIMARY KEY (db_name,table_name,key_name)
		   )
},
		      c_relationship => q{
CREATE TABLE c_relationship (
			     db_name varchar(50) DEFAULT '' NOT NULL,
			     fk_table varchar(50) DEFAULT '' NOT NULL,
			     fk_key varchar(50) DEFAULT '' NOT NULL,
			     pk_table varchar(50) DEFAULT '' NOT NULL,
			     PRIMARY KEY (db_name,fk_table,fk_key,pk_table)
			    )
},
		      c_table => q{
CREATE TABLE c_table (
		      table_name varchar(50) DEFAULT '' NOT NULL,
		      db_name varchar(50) DEFAULT '' NOT NULL,
		      PRIMARY KEY (table_name,db_name)
		     )
} },
	   mSQL => { c_db => q{
CREATE TABLE c_db (
		   db_name char(50) NOT NULL
		  )
},
		     c_key => q{
CREATE TABLE c_key (
		    db_name char(50) NOT NULL,
		    table_name char(50) NOT NULL,
		    key_name char(50) NOT NULL,
		    key_type int NOT NULL,
		    key_columns char(255) NOT NULL
)
},
		     c_relationship => q{
CREATE TABLE c_relationship (
			     db_name char(50) NOT NULL,
			     fk_table char(50) NOT NULL,
			     fk_key char(50) NOT NULL,
			     pk_table char(50) NOT NULL
			    )
},
		     c_table => q{
CREATE TABLE c_table (
		      table_name char(50) NOT NULL,
		      db_name char(50) NOT NULL
		     )
} }
	 }
}

package Foo;
use strict;
use base qw(DbFramework::Util);

my %fields = (
	      NAME       => undef,
	      CONTAINS_H => undef,
	     );

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;
  $self->name(shift);
  $self->contains_h(shift);
  return $self;
}

package main;
my $foo = new Foo('foo',['foo','oof','bar','rab','baz','zab']);
my @names = $foo->contains_h_byname('foo','bar');
ok("@names",'oof rab');

