#!/usr/local/bin/eperl -I../.. -mc
<?
=pod

=head1 NAME

dbforms.cgi - Forms interface to DbFramework databases

=head1 SYNOPSIS

  http://foo/cgi_bin/dbforms.cgi?driver=mysql&db=foo

=head1 DESCRIPTION

B<dbforms.cgi> is a CGI script which presents a simple HTML forms
interface to any database configured to work with B<DbFramework>.  Any
database you wish to work with B<must> have the appropriate catalog
entries in the catalog database before it will work with this script
(see L<DbFramework::Catalog/"The Catalog">.)

=head2 Query string arguments

The following arguments are supported in the query string.

=over 4

=item host

The host on which the database is located (default = 'localhost'.)

=item driver

The name of the DBI driver to use to connect to the database i.e. the
bit after B<DBD::> (default = 'mysql'.)

=item db

The name of the database to work with.

=back

=head1 SEE ALSO

L<DbFramework::Catalog>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

  use lib '../..';
  use DbFramework::Util;
  use DbFramework::Persistent;
  use DbFramework::DataModel;
  use DbFramework::Template;
  use CGI qw/:standard/;
  use URI::Escape;

  $cgi    = new CGI;
  $db     = $cgi->param('db')      || die "No database specified";
  $driver = $cgi->param('driver')  || 'mysql';
  $host   = $cgi->param('host')    || undef;
  $form   = $cgi->param('form')    || 'input';
  $action = $cgi->param('action')  || 'select';
  $dm     = new DbFramework::DataModel($db,"DBI:$driver:database=$db;host=$host");
  $dm->dbh->{PrintError} = 0;  # ePerl chokes on STDERR
  $dbh = $dm->dbh; $dbh->{PrintError} = 0;
  $dm->init_db_metadata;

  @tables = @{$dm->collects_table_l};
  $class  = $table = $cgi->param('table') || $tables[0]->name;
  $template = new DbFramework::Template(undef,\@tables);
  $template->default($table);

  $code   = DbFramework::Persistent->make_class($class);
  eval $code;

  package main;
  ($t)   = $dm->collects_table_h_byname($table);
  $thing = new $class($t,$dbh);
  cgi_set_attributes($thing);

#  unless ( $form eq 'input' ) {
#    $thing->init_pk;
#    $thing->table->read_form($form);
#  }

  # unpack composite column name parameters
  for my $param ( $cgi->param ) {
    if ( $param =~ /,/ ) {
      my @columns = split /,/,$param;
      my @values  = split /,/,$cgi->param($param);
      for ( my $i = 0; $i <= $#columns; $i++ ) {
	$cgi->param($columns[$i],$values[$i]);
      }
    }
  }
  sub cgi_set_attributes {
    my $thing = shift;
    my %attributes;
    for ( $thing->table->attribute_names ) {
      $attributes{$_} = $cgi->param($_) ne '' ? $cgi->param($_) : undef;
    }
    $thing->attributes_h([%attributes]);
  }

  sub error {
    my $message = shift;
    print  "<font color=#ff0000><strong>ERROR!</strong><p>$message</font>\n";
  }
!>
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
  <head>
    <title><? print "$db: $table" !></title>
  </head>

  <body>
  <table border=1>
    <tr>
      <td valign=top>
      <table>
        <tr>
          <td valign=top>
          <h1>db: <?=$db!></h1>
          </td>
        </tr>
        <tr>
          <td>
            <h4>Tables</h4>
            <ul>
<?
  for ( @{$dm->collects_table_l} ) {
    my $table = $_->name;
    print "<li><a href=",$cgi->url,"?driver=$driver&db=$db&host=$host&table=$table>$table</a>\n";
  }
!>
            </ul>
          </td>
        </tr>
      </table>
      </td>
      <td valign=top>
        <table border=0>
        <tr>
          <td colspan=2 align=middle>
            <h1><?=$table!></h1>
          </td>
        </tr>
        <tr>
          <td>
<? if ( $form eq 'input' ) { _!>
            <form method=post action=<? print $cgi->self_url !>>
<?
	    for ( qw(host driver db table form) ) {
	      print "<input type=hidden name=$_ value=",$$_,">\n";
	    }
            print $thing->table->as_html_heading;
!>
            <tr>
	      <?print $template->fill($thing->table_qualified_attribute_hashref)!>
              <td><input type=radio name=action value=select <?print 'checked' if $action eq 'select'!>> select</td>
              <td><input type=radio name=action value=insert <?print 'checked' if $action eq 'insert'!>> insert</td>
              <td><input type=submit value="Submit"></td>
             </form>
<? } !>
            </tr>
          </td>
        </tr>

<?
my $action = $cgi->param('action') || '';

SWITCH: {
  $action eq 'select' &&
    do { 
      my @names = $thing->table->attribute_names;
      my $conditions;
      for ( @names ) {
	if ( $cgi->param($_) ) {
	  $conditions .= " AND " if $conditions;
	  if ( $thing->table->in_foreign_key($thing->table->contains_h_byname($_)) ) {
	    $conditions .= "$_ = " . $cgi->param($_);
	  } else {
	    $conditions .= "$_ " . $cgi->param($_);
	  }
	}
      }
      my @things = eval { $thing->select($conditions) };
      if ( $@ ) {
	error($@);
      } else {
	if ( @things ) {
	  for my $thing ( @things ) {
	    my %attributes = %{$thing->attributes_h};
	    my $url = $cgi->url . "?db=$db&host=$host&table=$table&form=$form&action=update";
	    for ( keys(%attributes) ) {
	      #print STDERR "$_ = $attributes{$_}\n";
	      $url .= uri_escape("&$_=$attributes{$_}");
	    }
	    # fill template
	    my $values_hashref = $thing->attributes_h;
	    
	    $DEBUG = 0;
	    print STDERR $thing->table->template_h_byname($form) if $DEBUG;
	    print "<form method=post action=",$cgi->self_url,">\n";
	    for ( qw(host driver db table form) ) {
	      print "<input type=hidden name=$_ value=",$$_,">\n";
	    }
	    print "<TR>",$template->fill($thing->table_qualified_attribute_hashref),"\n";
	    print "<td><input type=radio name=action value=update",($action eq 'select') ? ' checked>' : '',"update</td>\n";
	    print "<td><input type=radio name=action value=delete>",($action eq 'delete') ? ' checked' : '',"delete</td>\n";
	    print "<td><input type=submit value='Submit'></td></tr></form>\n";
	  }
	} else {
	  print "<TR><TD><strong>No rows matched your query</strong></TD></TR>\n";
	}
      }
      last SWITCH;
    };
  $action =~ /^(insert|update|delete)$/ &&
    do {
      cgi_set_attributes($thing);
      eval { $thing->$action() };
      error($@) if $@;
    }
}
  $dm->dbh->disconnect;
  $dbh->disconnect;
!>
     </table>
    </td>
  </tr>
</table>
</body>
</html>
