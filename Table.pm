=head1 NAME

DbFramework::Table - Table class

=head1 SYNOPSIS

  use DbFramework::Table;

  $t = new DbFramework::Table($name,,,$dbh,\@forms);
  $t->init_db_metadata;
  $dbh = $t->dbh($dbh);
  $pk   = $t->is_identified_by($pk);
  @fks  = @{$t->has_foreign_keys_l};
  @keys = @{$t->is_accessed_using_l};
  @a    = $t->get_attributes(@names);
  @n    = $t->get_attribute_names;
  $html = $t->as_html_form;
  $s    = $t->as_string;
  $sql  = $t->as_sql;
  $rows = $t->delete($conditions);
  $pk   = $t->insert(\%values);
  $rows = $t->update(\%values,$conditions);
  @lol  = $t->select(\@columns,$conditions,$order);
  $tmpl = $t->set_templates(\%templates);
  $fill = $t->fill_template($template);
  do_something if $t->in_foreign_key($attribute);
  do_something if $t->in_key($attribute);
  do_something if $t->in_primary_key($attribute);
  do_something if $t->in_any_key($attribute);
  @a = $t->non_key_attributes;
  $t->read_form($form,$dir);

=head1 DESCRIPTION

A B<DbFramework::Table> object represents a database table (entity).

=head2 Forms and Templates

A table can have a number of associated forms.  Each form defines a
number of templates which can be used for data entry or display.
Forms associated with a table can be configured when calling new()
and/or by including the Perl code

C<$self-E<gt>form_h([form =E<gt> 'formfile' ...]);>

in the file F</usr/local/etc/dbframework/forms/$db/$table/config.pl>.
B<form> is a name used to identify the form and B<formfile> is the
name of the file containing the form definition.

Form files should be place in
F</usr/local/etc/dbframework/forms/$db/$table>.  They should contain a
list of (B<template name>,B<template>) pairs, where B<template name>
is a name used to identify the template and B<template> is an HTML
template.  Templates can be initialised by reading form files with the
read_form() method.  The special tags which can be used in a template
are described in the fill_template() method.

All lines in F<config.pl> and I<formfile> matching the regular
expression B</^\s*#/> will be treated as comments and ignored.

=head1 SUPERCLASSES

B<DbFramework::DefinitionObject>

B<DbFramework::DataModelObject>

=cut

package DbFramework::Table;
use strict;
use vars qw( $NAME @CONTAINS_L $IS_IDENTIFIED_BY $_DEBUG @IS_ACCESSED_USING_L
	     @HAS_FOREIGN_KEYS_L $DBH %TEMPLATE_H @CGI_PK %FORM_H );
use base qw(DbFramework::DefinitionObject DbFramework::DataModelObject);
use DbFramework::PrimaryKey;
use DbFramework::DataType;
use DbFramework::Attribute;
use Alias;
use Carp;
use CGI;

# CLASS DATA

my %fields = (
	      # Entity 1:1 IsIdentifiedBy 1:1 PrimaryKey
	      IS_IDENTIFIED_BY    => undef,
	      # Entity 1:1 HasForeignKeys 0:N ForeignKey
	      HAS_FOREIGN_KEYS_L  => undef,
	      HAS_FOREIGN_KEYS_H  => undef,
	      # Table 1:1 IsAccessedUsing 0:N Key
	      IS_ACCESSED_USING_L => undef,
	      DBH                 => undef,
	      TEMPLATE_H          => undef,
	      FORM_H              => undef,
	     );
my $formsdir = '/usr/local/etc/dbframework/forms';

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($name,\@attributes,$primary,$dbh,\@forms)

Create a new B<DbFramework::Table> object.  I<$dbh> is a DBI database
handle which refers to a database containing a table named I<$table>.
I<@attribues> is a list of B<DbFramework::Attribute> objects.
I<$primary> is a B<DbFramework::PrimaryKey> object.  I<@attributes>
and I<$primary> can be omitted if you plan to use the
B<init_db_metadata()> object method (see below).  I<@forms> is a list
of (I<form name>,I<file>) pairs.  Form files should contain a list of
(I<template name>,I<template>) pairs. (see the object method
read_form() below.)

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless($class->SUPER::new(shift,shift),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  $self->is_identified_by(shift);
  $self->dbh(shift);
  attr $self;
  my $config = "$formsdir/" . $self->get_db($DBH) . "/$NAME/config.pl";
  # table configuration
  if ( -f $config ) {
    my $code = _readfile_no_comments($config,"Couldn't open form config");
    eval $code;
  }
  $self->form_h($_[0]) if $_[0];
  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

Foreign keys in a table can be accessed using the
I<HAS_FOREIGN_KEYS_L> and I<HAS_FOREIGN_KEYS_H> attributes.  B<Note>
that foreign key objects will not be created automatically by calling
init_db_metadata() on a table object.  If you want to automatically
create foreign key objects for your tables you should use call
init_db_metadata() on a data model object (see
L<DbFramework::Datamodel/init_db_metadata()>).  Other keys (indexes)
defined for a table can be accessed using the I<IS_ACCESSED_USING_L>
attribute.  See L<DbFramework::Util/AUTOLOAD()> for the accessor
methods for these attributes.

=head2 is_identified_by($primary)

I<$primary> is a B<DbFramework::PrimaryKey> object.  If supplied, sets
the table's primary key to I<$primary>.  Returns a
B<DbFramework::PrimaryKey> object with is the table's primary key.

=head2 get_attributes(@names)

Returns a list of B<DbFramework::Attribute> objects.  I<@names> is a
list of attribute names to return.  If I<@names> is undefined, all
attributes associated with the table are returned.

=head2 dbh($dbh)

I<$dbh> is a DBI database handle.  If supplied, sets the database
handle associated with the table.  Returns the database handle
associated with the table.

=cut

sub get_attributes {
  my $self = attr shift;
  print STDERR "getting attributes for (",join(',',@_),")\n" if $_DEBUG;
  return @_ ? $self->contains_h_byname(@_) # specific attributes
            : @{$self->contains_l};	   # all attributes
}

##-----------------------------------------------------------------------------

=head2 get_attribute_names()

Returns a list of attribute names for the table.

=cut

sub get_attribute_names {
  my $self = attr shift;
  my @names;
  for ( @CONTAINS_L ) { push(@names,$_->name) }
  @names;
}

#------------------------------------------------------------------------------

=head2 as_html_form()

Returns HTML form fields for all attributes in the table.

=cut

sub as_html_form {
  my $self = attr shift;
  my $form;
  for ( @CONTAINS_L ) { $form .= "<tr><td>" . $_->as_html_form_field . "</td></tr>\n" }
  $form;
}

#------------------------------------------------------------------------------

=head2 in_foreign_key($attribute)

I<$attribute> is a B<DbFramework::Attribute> object.  Returns true if
I<$attribute> is a part of any foreign key in the table.

=cut

sub in_foreign_key {
  my($self,$attribute) = (attr shift,shift);
  my $name = $attribute->name;
  my @fk_names = ();
  print STDERR "foreign keys: @HAS_FOREIGN_KEYS_L\n" if $_DEBUG;
  for ( @HAS_FOREIGN_KEYS_L ) { push(@fk_names,$_->attribute_names) }
  print STDERR "Looking for $name in @fk_names\n" if $_DEBUG;
  return grep(/^$name$/,@fk_names) ? 1 : 0;
}

#------------------------------------------------------------------------------

=head2 in_primary_key($attribute)

I<$attribute> is a B<DbFramework::Attribute> object.  Returns true if
I<$attribute> is a part of the primary key in the table.

=cut

sub in_primary_key {
  my($self,$attribute) = (attr shift,shift);
  my $name     = $attribute->name;
  my @pk_names = $self->is_identified_by->attribute_names;
  print STDERR "Looking for $name in @pk_names\n" if $_DEBUG;
  return grep(/^$name$/,@pk_names) ? 1 : 0;
}

#------------------------------------------------------------------------------

=head2 in_key($attribute)

I<$attribute> is a B<DbFramework::Attribute> object.  Returns true if
I<$attribute> is a part of a key (index) in the table.

=cut

sub in_key {
  my($self,$attribute) = (attr shift,shift);
  my @k_names = ();
  my $name    = $attribute->name;
  for ( @IS_ACCESSED_USING_L ) { push(@k_names,$_->attribute_names) }
  print STDERR "Looking for $name in @k_names\n" if $_DEBUG;
  return grep(/^$name$/,@k_names) ? 1 : 0;
}

#------------------------------------------------------------------------------

=head2 in_any_key($attribute)

I<$attribute> is a B<DbFramework::Attribute> object.  Returns true if
I<$attribute> is a part of a key (index), a primary key or a foreign
key in the table.

=cut

sub in_any_key {
  my($self,$attribute) = (attr shift,shift);
  print STDERR "$self->in_any_key($attribute)\n" if $_DEBUG;
  return ($self->in_key($attribute)         ||
	  $self->in_primary_key($attribute) ||
	  $self->in_foreign_key($attribute)) ? 1 : 0;
}

#------------------------------------------------------------------------------

=head2 non_key_attributes()

Returns a list of B<DbFramework::Attribute> objects which are not
members of any key, primary key or foreign key.

=cut

sub non_key_attributes {
  my $self = attr shift;
  my @non_key;
  for ( @CONTAINS_L ) { push(@non_key,$_) unless $self->in_any_key($_) }
  @non_key;
}

#------------------------------------------------------------------------------

#=head2 html_hidden_pk_list()

#Returns a 'hidden' HTML form field whose key consists of the primary
#key column names separated by '+' characters and whose value is the
#current list of @CGI_PK

#=cut

#sub html_hidden_pk_list {
#  my $self   = attr shift;
#  my $cgi    = new CGI('');
#  return $cgi->hidden(join('+',@{$PRIMARY->column_names}),@CGI_PK) . "\n";
#}

#------------------------------------------------------------------------------

=head2 as_string()

Return table details as a string.

=cut

sub as_string {
  my $self = attr shift;
  my $s    = "Table: $NAME\n";
  for ( @{$self->contains_l} ) { $s .= $_->as_string }
  return $s;
}

##-----------------------------------------------------------------------------

=head2 init_db_metadata()

Returns an initialised B<DbFramework::Table> object for the table
matching this object's name() in the database referenced by dbh().

=cut

sub init_db_metadata {
  my $self  = attr shift;

  my($sql,$sth,$rows,$rv);
  $sql   = qq{DESCRIBE $NAME};
  $sth   = $DBH->prepare($sql) || die($DBH->errstr);
  $rv    = $sth->execute       || die($sth->errstr);
  $rows  = $sth->rows;
  my @columns;
  for ( my $i = 1; $i <= $rows; $i++ ) {
    my %row = %{$sth->fetchrow_hashref};
    
    my $d = new DbFramework::DataType($row{Type} =~ /^(\w+)\(*.*$/,
                                      $row{Type} =~ /^\w+\((\d+)\)$/,
                                      $row{Extra}
                                     );
    my $a = new DbFramework::Attribute($row{Field},
                                       $row{Default},
                                       $row{Null} eq 'YES' ? 1 : 0,
                                       $d
                                      );
    push(@columns,$a);
  }
  $self->_init(\@columns);

  ## add keys
  my(%keys,$key,@row,@keys);
  $sql = qq{SHOW KEYS FROM $NAME};
  $sth = $DBH->prepare($sql) || die($DBH->errstr);
  $rv  = $sth->execute       || die($sth->errstr);
  while ( @row = $sth->fetchrow_array ) {
    push(@{$keys{$row[2]}},$row[4]);
  }

  for ( keys(%keys) ) {
    my @attributes = $self->get_attributes(@{$keys{$_}});
    if ( $_ eq 'PRIMARY' ) {    # primary key
      my $pk = new DbFramework::PrimaryKey(\@attributes);
      $pk->belongs_to($self);   # reverse reference
      $self->is_identified_by($pk);
    } elsif ( $_ !~ /^f_/i ) {  # key (not foreign)
      my $k = new DbFramework::Key($_,\@attributes);
      $k->belongs_to($self);    # reverse reference
      push(@keys,$k);
    }
  }
  $self->is_accessed_using_l(\@keys);
  die "no primary key defined in $NAME" unless defined($IS_IDENTIFIED_BY);

  $self->_templates;  # set default templates

  return $self;
}

#------------------------------------------------------------------------------

=head2 as_sql()

Returns a string which can be used to create a table in an SQL 'CREATE
TABLE' statement.

=cut

sub as_sql {
  my $self = attr shift;
  my $sql = "CREATE TABLE $NAME (\n";
  for ( @{$self->contains_l} ) { $sql .= "\t" . $_->as_sql($DBH) . ",\n"; }
  $sql .= "\t" . $IS_IDENTIFIED_BY->as_sql;
  for ( @IS_ACCESSED_USING_L ) { $sql .= ",\n\t" . $_->as_sql }
  for ( @HAS_FOREIGN_KEYS_L )  { $sql .= ",\n\t" . $_->as_sql }
  return "$sql\n)";
}

#------------------------------------------------------------------------------

#=head2 validate_foreign_keys()

#Ensure that foreign key definitions match related primary key
#definitions.

#=cut

sub validate_foreign_keys {
  my $self = shift;
  attr $self;

  for my $fk ( @HAS_FOREIGN_KEYS_L ) {
    my $fk_name       = $fk->name;
    my @fk_attributes = @{$fk->incorporates_l};
    my @pk_attributes = @{$fk->references->incorporates_l};
    @fk_attributes == @pk_attributes ||
      die "Number of attributes in foreign key $NAME:$fk_name(",scalar(@fk_attributes),") doesn't match that of related primary key (",scalar(@pk_attributes),")";
    for ( my $i = 0; $i <= $#fk_attributes; $i++) {
      my($fk_aname,$pk_aname) =
        ($fk_attributes[$i]->name,$pk_attributes[$i]->name);
      print STDERR "$fk_aname eq $pk_aname\n" if $_DEBUG;
      #$fk_aname eq $pk_aname ||
      #  die "foreign key component $NAME:$fk_aname ne primary key component $pk_aname\n";
    }
  }
}

#------------------------------------------------------------------------------

=head2 delete($conditions)

B<DELETE> rows B<FROM> the table associated with this object B<WHERE>
the conditions in I<$conditions> are met.  Returns the number of rows
deleted.

=cut

sub delete {
  my($self,$conditions) = (attr shift,shift);

  my $sql  = "DELETE FROM $NAME";
     $sql .= " WHERE $conditions" if $conditions;
  print STDERR "$sql\n" if $_DEBUG;
  return $DBH->do($sql) || die($DBH->errstr);
}
#------------------------------------------------------------------------------

=head2 insert(\%values)

B<INSERT INTO> the table columns corresponding to the keys of
I<%values> the B<VALUES> corresponding to the values I<%values>.
Returns the primary key of the inserted row if it is a Mysql
'AUTO_INCREMENT' column.

=cut

sub insert {
  my $self   = attr shift;
  my %values = %{$_[0]};

  my $columns = '(' . join(',',keys(%values)). ')';
  my $values;
  for ( values(%values) ) { $values .= $DBH->quote($_) . ',' }
  chop $values;

  my $sql = "INSERT INTO $NAME $columns VALUES ($values)";
  print STDERR "$sql\n" if $_DEBUG;
  my $sth = $DBH->prepare($sql) || die $DBH->errstr;
  my $rv  = $sth->execute       || die "$sql\n" . $sth->errstr . "\n";
  my $rc  = $sth->finish;

  return $sth->{'insertid'}; # id of auto_increment field (DBD::mysql specific)
}
#------------------------------------------------------------------------------

=head2 update(\%values,$conditions)

B<UPDATE> the table B<SET>ting the columns matching the keys in
%values to the values in %values B<WHERE> I<$conditions> are
met. Returns the number of rows updated.

=cut

sub update {
  my $self = attr shift;
  my %values     = %{$_[0]};
  my $conditions = $_[1];

  my $values;
  for ( keys %values ) { $values .= "$_ = " . $DBH->quote($values{$_}) . ',' }
  chop $values;
  
  my $sql  = "UPDATE $NAME SET $values";
     $sql .= " WHERE $conditions" if $conditions;
  print STDERR "$sql\n" if $_DEBUG;
  return $DBH->do($sql) || die($DBH->errstr);
}

#------------------------------------------------------------------------------

=head2 select(\@columns,$conditions,$order)

Returns a list of lists of values by B<SELECT>ing rows B<FROM> the
table B<WHERE> I<$conditions> are met B<ORDER>ed B<BY> I<$order>.

=cut

sub select {
  my $self = attr shift;
  my @columns = defined($_[0]) ? @{$_[0]} : @{$self->get_attribute_names};
  my($conditions,$order) = @_[1..2];
  my $sql        = "SELECT " . join(',',@columns) . " FROM $NAME";
     $sql       .= " WHERE $conditions" if $conditions;
     $sql       .= " ORDER BY $order"   if $order;
  print STDERR "$sql\n" if $_DEBUG;
  my $sth        = $DBH->prepare($sql) || die($DBH->errstr);
  my $rv         = $sth->execute       || die "$sql\n" . $sth->errstr . "\n";
  my @things;
  # WARNING!
  # Can't use fetchrow_arrayref here as it returns the *same* ref (man DBI)
  while ( my @attributes = $sth->fetchrow_array ) {
    print "@attributes\n" if $_DEBUG;
    push(@things,\@attributes);
  }
  if ( $_DEBUG ) {
    print "@things\n";
    for ( @things ) { print "@{$_}\n" }
  }
  return @things;
}
##-----------------------------------------------------------------------------

=head2 fill_template($name,\%values)

Return the filled HTML template named I<$name>.  A template can
contain special placeholders representing columns in a database table.
Placeholders in I<$template> can take the following forms:

=over 4

=item B<E<lt>DbField table.columnE<gt>>

=item B<E<lt>DbField table.column value=valueE<gt>>

=item B<E<lt>DbField table.column value=value type=typeE<gt>>

=back

If the table's name() matches I<table> in a B<DbField> placeholder,
the placeholder will be replaced with the corresponding HTML form
field for the column named I<column> with arguments I<value> and
I<type> (see L<DbFramework::Attribute/html_form_field()>).  If
I<%values> is supplied placeholders will have the values in I<%values>
added where a key in I<%values> matches a column name in the table.

=over 4

=item B<E<lt>DbFKey table.fk_name[,column...]E<gt>>

=back

If the table's name() matches I<table> in a B<DbFKey> placeholder, the
placeholder will be replaced with the a selection box containing
values and labels from the primary key columns in the related table.
Primary key attribute values in I<%values> will be used to select the
default item in the selection box.

=over 4

=item B<E<lt>DbValue table.column[,column...]E<gt>>

=back

If the table's name() matches I<table> in a B<DbValue> placeholder,
the placeholder will be replaced with the values in I<%values> where a
key in I<%values> matches a column name in the table.

=cut

sub fill_template {
  my($self,$name,$values) = (attr shift,shift,shift);
  print STDERR "filling template '$name' for table '$NAME'\n" if $_DEBUG;
  return '' unless exists $TEMPLATE_H{$name};
  my $template = $TEMPLATE_H{$name};

  #print STDERR "template = \n$TEMPLATE_H{$name}\n\$values = ",%$values,"\n" if $_DEBUG;


  # insert values into template
  if ( defined($values) ) {
    $template =~ s/(<DbField\s+$NAME\.)(\w+)(\s+value=)(.*?\s*)>/$1$2 value=$values->{$2}>/g;
    $template =~ s/(<DbField $NAME\.)(\w+)>/$1$2 value=$values->{$2}>/g;
    # handle multiple attributes here for foreign key values
    $template =~ s/<DbValue\s+$NAME\.([\w,]+)\s*>/join(',',@{$values}{split(m{,},$1)})/eg;
  }

  #print STDERR "template = \n$TEMPLATE_H{$name}\n\$values = ",%$values,"\n" if $_DEBUG;

  # foreign key placeholders
  my %fk = %{$self->has_foreign_keys_h};
  $template =~ s/<DbFKey\s+$NAME\.(\w+)\s*>/$fk{$1}->as_html_form_field($values)/eg;

  # form field placeholders
  $template =~ s/<DbField\s+$NAME\.(\w+)\s+value=(.*?)\s+type=(.*?)>/$self->_as_html_form_field($1,$2,$3)/eg;
  $template =~ s/<DbField\s+$NAME\.(\w+)\s+value=(.*?)>/$self->_as_html_form_field($1,$2)/eg;
  $template =~ s/<DbField $NAME\.(\w+)>/$self->_as_html_form_field($1)/eg;

  $template;
}

#------------------------------------------------------------------------------

sub _as_html_form_field {
  my($self,$attribute) = (shift,shift);
  my @attributes = $self->get_attributes($attribute);
  $attributes[0]->as_html_form_field(@_);
}

#------------------------------------------------------------------------------

=head2 set_templates(%templates)

Adds the contents of the files which are the values in I<%templates>
as templates named by the keys in I<%templates>.  Returns a reference
to a hash of all templates.

=cut

sub set_templates {
  my $self = attr shift;
  if ( @_ ) {
    my %templates = @_;
    my @templates;
    for ( keys %templates ) {
      open(T,"<$templates{$_}") || die "Couldn't open template $templates{$_}";
      my @t = <T>;
      close T;
      push(@templates,$_,"@t");
    }
    $self->template_h(\@templates);
  }
  \%TEMPLATE_H;
}

#------------------------------------------------------------------------------

sub _templates {
  my $self = attr shift;
  $self->_template('input','_input_template');
  $self->_template('output','_output_template');
}

#------------------------------------------------------------------------------

sub _template {
  my($self,$key,$method) = (attr shift,shift,shift);
  my @fk_attributes;
  for ( @HAS_FOREIGN_KEYS_L ) { push(@fk_attributes,$_->attribute_names) }
  my $t = $IS_IDENTIFIED_BY->$method(@fk_attributes) || '';
  for ( $self->non_key_attributes ) { $t .= $_->$method($NAME) }
  for ( @IS_ACCESSED_USING_L )      { $t .= $_->$method() }
  for ( @HAS_FOREIGN_KEYS_L )       { $t .= $_->$method() }
  $self->template_h_add({$key => $t});
}

#------------------------------------------------------------------------------

=head2 read_form($form,$dir)

Configure templates by evaluating the contents of
F<$dir/$db/$table/$form> where I<$dir> is a directory
(F</usr/local/etc/dbframework> by default), I<$db> is the name of the
database containing the table, I<$table> is the name of the table and
I<$form> is the name of the form containing the template definitions.
See L<Forms and Templates>.

=cut

sub read_form {
  my $self = attr shift;
  my $dir  = $_[1] || $formsdir;
  my $form = "$dir/".$self->get_db($DBH)."/$NAME/$FORM_H{$_[0]}";
  my $templates = _readfile_no_comments($form,"Couldn't open form");
  %TEMPLATE_H = eval $templates;
}

#------------------------------------------------------------------------------

sub _readfile_no_comments {
  my($file,$error) = @_;
  open FH,"<$file" or die "$error: $file: $!";
  my $lines;
  while (<FH>) {
    next if /^\s*#/;
    $lines .= $_;
  }
  close FH;
  $lines;
}

#------------------------------------------------------------------------------

=head2 as_html_heading()

Returns a string for use as a table heading row in an HTML table;

=cut

sub as_html_heading {
  my $self = attr shift;
  my $method = 'as_html_heading';
  my @fk_attributes;
  for ( @HAS_FOREIGN_KEYS_L ) { push(@fk_attributes,$_->attribute_names) }
  my $html = $IS_IDENTIFIED_BY->$method(@fk_attributes);
  for ( $self->non_key_attributes ) { $html .= $_->$method() }
  for ( @IS_ACCESSED_USING_L )      { $html .= $_->$method() }
  for ( @HAS_FOREIGN_KEYS_L )       { $html .= $_->$method() }
  "<TR>$html</TR>";
}

1;

=head1 SEE ALSO

L<DbFramework::DefinitionObject>, L<DbFramework::Attribute> and
L<DbFramework::DataModelObject>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

