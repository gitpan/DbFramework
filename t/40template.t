# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
use strict;
use Test;
use t::Config;

BEGIN { plan tests => scalar(@t::Config::drivers) * 5 + 1 }

use DbFramework::Template;
ok(1);
use DbFramework::DataModel;

for ( @t::Config::drivers ) { foo($_) }

sub foo($) {
  my($driver) = @_;

  my $db  = 'dbframework_test';
  my $dsn = "DBI:$driver:database=$db";
  my $dm  = new DbFramework::DataModel($db,$dsn);
  $dm->init_db_metadata;
  my $dbh = $dm->dbh; $dbh->{PrintError} = 0;

  my $t  = new DbFramework::Template("(:&db_value(foo.bar):)",
				     $dm->collects_table_l);
  ok(1);

  my $filling = 'bar';
  ok($t->fill({'foo.bar' => $filling}),$filling);

  $t->template->set_text("(:&db_html_form_field(foo.bar,,int):)");
  my $ok = '<INPUT NAME="bar" VALUE="" SIZE=10 TYPE="text">';
  ok($t->fill,$ok);

  $t->template->set_text("(:&db_fk_html_form_field(bar.f_foo):)");
  if ( $driver eq 'mysql' ) {
    $ok = qq{<SELECT NAME="foo_foo,foo_bar">
<OPTION  VALUE="">Any
<OPTION  VALUE="2,baz">2,baz,baz,0,NULL
</SELECT>
};
  } elsif ( $driver eq 'mSQL' ) {
    $ok = qq{<SELECT NAME="foo_foo,foo_bar">
<OPTION  VALUE="">Any
<OPTION  VALUE="0,bar">0,bar,NULL,NULL,NULL
</SELECT>
};
  }
  ok($t->fill,$ok);

  # default template
  $t->default('bar');
  if ( $driver eq 'mysql' ) {
    $ok = q{<TD><INPUT NAME="foo" VALUE="" SIZE=10 TYPE="text"></TD><TD><INPUT NAME="bar" VALUE="" SIZE=10 TYPE="text"></TD><TD><SELECT NAME="foo_foo,foo_bar">
<OPTION  VALUE="">Any
<OPTION  VALUE="2,baz">2,baz,baz,0,NULL
</SELECT>
</TD>};
  } elsif ( $driver eq 'mSQL' ) {
    $ok = q{<TD><INPUT NAME="foo" VALUE="" SIZE=10 TYPE="text"></TD><TD><INPUT NAME="bar" VALUE="" SIZE=10 TYPE="text"></TD><TD><SELECT NAME="foo_foo,foo_bar">
<OPTION  VALUE="">Any
<OPTION  VALUE="0,bar">0,bar,NULL,NULL,NULL
</SELECT>
</TD>};
  }
  ok($t->fill,$ok);
}
