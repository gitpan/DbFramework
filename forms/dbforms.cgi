#!/usr/local/bin/eperl -mc
<?
  use lib qw{/usr/local/import/spwebdev/share/home/paul/work/DbFramework-release-1-0/blib/lib /home/paul/src/DbFramework-release-1-0/blib/lib};
  use DbFramework::Util;
  use DbFramework::Persistent;
  use DbFramework::DataModel;
  use CGI qw/:standard/;
  use URI::Escape;

  my $cgi = new CGI;

  # map tables to classes
  my %things = ( song   => 'Song',
		 artist => 'Artist',
	       );
  my $db     = $cgi->param('db')      || die "No database specified";
  my $host   = $cgi->param('host')    || undef;
  my $action = $cgi->param('action')  || 'select';
  my $dbh    = DbFramework::Util::get_dbh($db,$host);
  my $dm     = new DbFramework::DataModel($db,$db,$host);
  $dm->dbh->{PrintError} = 0;  # ePerl chokes on STDERR
  my @tables = @{$dm->collects_table_l};
  my $table  = $cgi->param('table')   || $tables[0]->name;

  my $code   = DbFramework::Persistent->make_class($table);
  eval $code;

  package main;
  my $class = $table;
  my($t)    = $dm->collects_table_h_byname($table);
  my $thing = new $class($t,$dbh);
  cgi_set_attributes($thing);
  eval { $thing->table->template("$table.html") };

  sub cgi_set_attributes {
    my $thing = shift;
    my @names = $thing->table->get_attribute_names;
    my %attributes;
    for ( @names ) { $attributes{$_} = $cgi->param($_) }
    $thing->attributes_h([%attributes]);
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
        <h1><?=$db!></h1>
        <ul>
    <?
    for ( @{$dm->collects_table_l} ) {
      my $table = $_->name;
      print "<li><a href=",$cgi->url,"?db=$db&host=$host&table=$table>$table</a>\n";
    }
    !>
        </ul>
      </td>
      <td>
    <h1><?=$table!></h1>
    <form method=post action=<? print $cgi->self_url !>>
    <table>
      <input type=hidden name=host value=<?=$host!>>
      <input type=hidden name=db value=<?=$db!>>
      <input type=hidden name=table value=<?=$table!>>
<?
  print $thing->fill_template('input');
!>
    </table>
    <table>
    <tr>
      <td>
        <input type=radio name=action value=select <?print 'checked' if $action eq 'select'!>> select
        <input type=radio name=action value=insert <?print 'checked' if $action eq 'insert'!>> insert
        <input type=radio name=action value=update <?print 'checked' if $action eq 'update'!>> update
        <input type=radio name=action value=delete <?print 'checked' if $action eq 'delete'!>> delete
       </td>
    </tr>
    <tr>
      <td><input type=submit value="Submit"></td>
    <tr>
    </table>
    </form>

<?
my $action = $cgi->param('action') || '';

SWITCH: {
  $action eq 'select' &&
    do { 
      my @names = $thing->table->get_attribute_names;
      my $conditions;
      for ( @names ) {
	if ( $cgi->param($_) ) {
	  $conditions .= " AND " if $conditions;
	  $conditions .= "$_ " . $cgi->param($_);
	}
      }
      print "<table border=1>\n";
      my @things = eval { $thing->select($conditions) };
      print  "<font color=#ff0000><strong>ERROR!</strong><p>$@</font>\n" if $@;
      for my $thing ( @things ) {
	my %attributes = %{$thing->attributes_h};
	my $url = $cgi->url . "?db=$db&host=$host&table=$table&action=update";
	for ( keys(%attributes) ) {
	  $url .= uri_escape("&$_=$attributes{$_}");
	}
	print "<TR>",$thing->fill_template('output'),"<TD><A HREF=$url>modify</A></TD></TR>\n";
      }
      print "</table>\n";
      last SWITCH;
    };
  $action =~ /^(insert|update|delete)$/ &&
    do {
      cgi_set_attributes($thing);
      if ( $action eq 'insert' ) {
	$thing->insert;
      } elsif ( $action eq 'update' ) {
	$thing->update;
      } elsif ( $action eq 'delete' ) {
	$thing->delete;
      }
    }
}
  $dm->dbh->disconnect;
  $dbh->disconnect;
!>

</td>
</tr>
</table>
</body>
</html>
