=head1 NAME

DbFramework::Persistent - Persistent Perl object base class

=head1 SYNOPSIS

  package Foo;
  use base qw(DbFramework::Persistent);

  package main;
  $foo = new Foo($table,$dbh);
  $foo->attributes_h(\%foo};
  $foo->insert;
  $foo->attributes_h(\%new_foo);
  $foo->update;
  $foo->delete;
  @foo = $foo->select($condition);

=head1 DESCRIPTION

Base class for persistent objects which use a Mysql database for
storage.  To create your own persistent object classes subclass
B<DbFramework::Persistent> e.g.

  package Foo;
  use base qw(DbFramework::Persistent);

  package main;
  ... # make a dbh
  $foo = new Foo($table,$dbh);
  $foo->attributes_h(\%foo};
  $fill = $foo->fill_template;
  $foo->insert;
  $foo->attributes_h(\%new_foo);
  $foo->update;
  $foo->delete;
  @foo = $foo->select($condition);
  $html = $foo->as_html_form;

=head1 SUPERCLASSES

B<DbFramework::Util>

=cut

package DbFramework::Persistent;
use strict;
use vars qw( $TABLE $_DEBUG $VERSION );
$VERSION = '1.03';
use base qw(DbFramework::Util);
use Alias;
use DbFramework::Table;

## CLASS DATA

my $Debugging = 0;

my %fields = (
	      TABLE        => undef,
	      ATTRIBUTES_H => undef,
);

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($table,$dbh)

Create a new persistent object. I<$table> is a B<DbFramework::Table>
object or the name of a database table.  I<$dbh> is a B<DBI> database
handle which refers to a database containing a table associated with
I<$table>.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my($table,$dbh) = @_;
  my $self = bless { _PERMITTED => \%fields, %fields, }, $class;
  $table = new DbFramework::Table($table,undef,undef,$dbh)
    unless (ref($table) eq 'DbFramework::Table');
  $self->table($table->init_db_metadata);
  return $self;
}

##-----------------------------------------------------------------------------

=head2 make_class($name)

Make a new persistent object class called I<$name>.

=cut

sub make_class {
  my($proto,$name) = @_;
  my $class = ref($proto) || $proto;

  my $code = "package $name;\n";
  $code .= <<'EOF';
use strict;
use base qw(DbFramework::Persistent);
EOF

  return $code;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

Attributes in a persistent object which relate to columns in the
associated table are made available through the attribute
I<ATTRIBUTES_H>.  See L<DbFramework::Util/AUTOLOAD()> for the accessor
methods for these attributes.

=head2 delete()

Delete this object from the associated table based on the values of
it's primary key attributes.  Returns the number of rows deleted.

=cut

sub delete {
  my $self = attr shift;
  return $TABLE->delete($self->_pk_conditions);
}

#------------------------------------------------------------------------------

=head2 insert()

Insert this object in the associated table.  Returns the primary key
of the inserted row if it is a Mysql 'AUTO_INCREMENT' column.

=cut

sub insert {
  my $self = attr shift;
  return $TABLE->insert($self->attributes_h);
}

#------------------------------------------------------------------------------

=head2 update()

Update this object in the associated table.  Returns the number of
rows updated.

=cut

sub update {
  my $self = attr shift;
  return $TABLE->update($self->attributes_h,$self->_pk_conditions);
}

#------------------------------------------------------------------------------

=head2 select($conditions)

Returns a list of objects of the same class as the object which
invokes it.  Each object in the list has its attributes initialised
from the values returned by selecting all columns from the associated
table matching I<$conditions>.

=cut

sub select {
  my $self = attr shift;

  my @things;
  my @columns = $TABLE->get_attribute_names;
  for ( $TABLE->select(\@columns,shift) ) {
    print STDERR "@{$_}\n" if $_DEBUG;
    my $thing = $self->new($TABLE->name,$TABLE->dbh);
    my %attributes;
    for ( my $i = 0; $i <= $#columns; $i++ ) {
      $attributes{$columns[$i]} = $_->[$i];
    }
    $thing->attributes_h([%attributes]);
    push(@things,$thing);
  }
  return @things;
}

##-----------------------------------------------------------------------------

#=head2 validate_required()

#Returns a list of attribute names which must B<not> be NULL but are
#undefined.  If I<@attributes> is undefined, validates all attributes.

#=cut

#sub validate_required {
#  my $self  = attr shift; my $table = $self->table;
#  my($attribute,@invalid);

#  my @attributes = @_ ? @_ : sort keys(%STATE);
#  foreach $attribute ( @attributes ) {
#    my $column = $table->get_column($attribute);
#    if ( ! $column->null && ! defined($self->get_attribute($attribute)) ) {
#      my $heading = $column->heading;
#      if ( $heading ) {
#	push(@invalid,$heading)
#      } else {
#	push(@invalid,$attribute);
#      }
#    }
#  }   
#  return @invalid;
#}

##-----------------------------------------------------------------------------

# return a SQL 'WHERE' clause condition consisting of primary key
# attributes and their corresponding values (from the object) joined
# by 'AND'
 
sub _pk_conditions {
  my $self = attr shift;

  my %attributes = %{$self->attributes_h};
  my $conditions;
  for ( $TABLE->is_identified_by->attribute_names ) {
    $conditions .= ' AND ' if $conditions;
    $conditions .= "$_ = " . $TABLE->dbh->quote($attributes{$_});
  }
  print STDERR "$conditions\n" if $_DEBUG;
  $conditions;
}

##-----------------------------------------------------------------------------

=head2 fill_template($name)

Returns the template named I<$name> in the table associated with this
object filled with the object's attribute values.  See
L<DbFramework::Table/"fill_template()">.

=cut

sub fill_template {
  my($self,$name) = (attr shift,shift);
  $TABLE->fill_template($name,$self->attributes_h);
}

##-----------------------------------------------------------------------------

=head2 as_html_form()

Returns an HTML form representing the object, filled with the object's
attribute values.

=cut

sub as_html_form {
  my $self = attr shift;
  my %attributes = %{$self->attributes_h};
  my $html;
  for ( @{$self->table->contains_l} ) {
    next if $self->table->in_foreign_key($_);
    my $name = $_->name;
    $html .= "<TR><TD><STRONG>$name</STRONG></TD><TD>"
          . $_->as_html_form_field($attributes{$name})
          .  "</TD></TR>\n";
  }
  return $html;
}

1;

=head1 SEE ALSO

L<DbFramework::Util> and L<DbFramework::Table>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

