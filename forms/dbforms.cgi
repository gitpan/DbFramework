#!/usr/local/bin/eperl -mc
<?
  use lib '../..';
  use DbFramework::Util;
  use DbFramework::Persistent;
  use DbFramework::DataModel;
  use CGI qw/:standard/;
  use URI::Escape;

  $cgi    = new CGI;
  $db     = $cgi->param('db')      || die "No database specified";
  $host   = $cgi->param('host')    || undef;
  $form   = $cgi->param('form')    || undef;
  $action = $cgi->param('action')  || 'select';
  $dbh    = DbFramework::Util::get_dbh($db,$host);
  $dm     = new DbFramework::DataModel($db,$db,$host);
  $dm->dbh->{PrintError} = 0;  # ePerl chokes on STDERR
  @tables = @{$dm->collects_table_l};
  $class  = $table = $cgi->param('table') || $tables[0]->name;

  $code   = DbFramework::Persistent->make_class($class);
  eval $code;

  package main;
  ($t)    = $dm->collects_table_h_byname($table);
  $thing = new $class($t,$dbh);
  cgi_set_attributes($thing);

  $thing->table->read_form($form) if $form; # configure templates
  #eval { $thing->table->template("$table.html") };

  sub cgi_set_attributes {
    my $thing = shift;
    my @names = $thing->table->get_attribute_names;
    my %attributes;
    for ( @names ) { $attributes{$_} = $cgi->param($_) }
    $thing->attributes_h([%attributes]);

  sub error {
    my $message = shift;
    print  "<font color=#ff0000><strong>ERROR!</strong><p>$message</font>\n";
  }
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
      <td>
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
    print "<li><a href=",$cgi->url,"?db=$db&host=$host&table=$table>$table</a>\n";
  }
!>
            </ul>
          </td>
        </tr>
        <tr>
          <td>
            <h4>Forms</h4>
            <ul>
<?
  for ( @{$dm->collects_table_l} ) {
    my $table = $_->name;
    for my $form ( keys(%{$_->form_h}) ) {
      print "<li><a href=",$cgi->url,"?db=$db&host=$host&table=$table&form=$form>$form</a>\n";
    }
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
            <form method=post action=<? print $cgi->self_url !>>
            <input type=hidden name=host value=<?=$host!>>
            <input type=hidden name=db value=<?=$db!>>
            <input type=hidden name=table value=<?=$table!>>
            <input type=hidden name=form value=<?=$form!>>
            <?print $thing->table->as_html_heading;!>
            <tr>
              <?print $thing->fill_template('input');!>
              <td><input type=radio name=action value=select <?print 'checked' if $action eq 'select'!>> select</td>
              <td><input type=radio name=action value=insert <?print 'checked' if $action eq 'insert'!>> insert</td>
              <td><input type=submit value="Submit"></td>
             </form>
            </tr>
          </td>
        </tr>

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
	    
	    $DEBUG  = 0;
	    print STDERR $thing->table->template_h_byname('input') if $DEBUG;
	    my $template = $thing->fill_template('input',$values_hashref);

=pod
	    for ( @{$thing->table->has_foreign_keys_l} ) {
	      my @fk_attributes = $_->attribute_names;
	      # can only handle single attribute fks
	      my($fk_value) = $thing->attributes_h_byname($fk_attributes[0]);
	      my $pk    = $_->references;
	      my $table = $pk->belongs_to;
	      my $class = $table->name;
	      my $code  = DbFramework::Persistent->make_class($class);
	      eval $code;
	      package main;
	      my $thing = new $class($table,$dbh);
	      my @pk_attributes = $pk->attribute_names;
	      # initialise thing based on fk value
	      ($thing) = $thing->select("$pk_attributes[0] = $fk_value");
	      $thing->table->template_h(['input',$template]);
	      $template = $thing->fill_template('input',$values_hashref);
	    }
=cut

	    print "<form method=post action=",$cgi->self_url,">\n";
	    for ( qw(host db table form) ) {
	      print "<input type=hidden name=$_ value=",$$_,">\n";
	    }
	    print "<TR>$template";
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
