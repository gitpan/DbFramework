=head1 NAME

DbFramework::DataModel - Data Model class

=head1 SYNOPSIS

  use DbFramework::DataModel;
  $dm = new DbFramework::DataModel($name,$db,$host,$port,$user,$pass);
  $dm->init_db_metadata;
  @tables = @{$dm->collects_table_l};
  %tables = %{$db->collects_table_h};
  @tables = @$db->collects_table_h_byname(@tables);
  $sql    = $db->as_sql;

=head1 DESCRIPTION

A B<DbFramework::DataModel> object represents a Mysql database schema.
It can be initialised using metadata from a Mysql database which is
structured according to a few simple rules.

=head1 SUPERCLASSES

B<DbFramework::Util>

=head1 DATA MODEL RULES

=head2 Foreign Keys

For B<init_db_metadata()> to handle foreign keys correctly,
each foreign key name must be of the form I<f_$table> where I<$table>
is the name of the table with the related primary key.

=cut

package DbFramework::DataModel;
use strict;
use vars qw( $NAME $_DEBUG @COLLECTS_TABLE_L $DBH );
use base qw(DbFramework::Util);
use DbFramework::Table;
use DbFramework::ForeignKey;
use Alias;

## CLASS DATA

my %fields = (
	      NAME       => undef,
	      # DataModel 0:N Collects 0:N DataModelObject
	      COLLECTS_L => undef,
	      # DataModel 0:N Collects 0:N Table
	      COLLECTS_TABLE_L => undef,
	      COLLECTS_TABLE_H => undef,
	      DBH => undef,	      
);

###############################################################################
# CLASS METHODS
###############################################################################

=head1 CLASS METHODS

=head2 new($name,$db,$host,$port,$user,$password)

Create a new B<DbFramework::DataModel> object called I<$name>.  I<$db>
is the name of a Mysql database associated with the data model.
I<$host>, I<$port>, I<$user>, I<$password> are optional arguments
specifying the host, port, username and password to use when
connecting to the database.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;
  $self->name(shift);
  $self->dbh(DbFramework::Util::get_dbh(@_));
  $self->init_db_metadata;
  return $self;
}

###############################################################################
# OBJECT METHODS
###############################################################################

=head1 OBJECT METHODS

A data model has a number of tables.  These tables can be accessed
using the attributes I<COLLECTS_TABLE_L> and I<COLLECTS_TABLE_H>.  See
L<DbFramework::Util/AUTOLOAD()> for the accessor methods for these
attributes.

=head2 name($name)

If I<$name> is supplied, sets the data model name.  Returns the data
model name.

=head2 as_sql()

Returns a SQL string which can be used to create the tables which make
up the data model.

=cut

sub as_sql {
  my $self = attr shift;
  my $sql;
  for ( @COLLECTS_TABLE_L ) { $sql .= $_->as_sql($DBH) . ";\n" }
  return $sql;
}

#------------------------------------------------------------------------------

=head2 init_db_metadata()

Returns a B<DbFramework::DataModel> object configured using metadata
from the Mysql database handle returned by dbh().  Foreign keys will
be automatically configured for tables in the data model (but see
L<"DATA MODEL RULES"> for information on foreign key names.)  This
method will die() unless the number of attributes and the attribute
names in each foreign and related primary keys match.

=cut

sub init_db_metadata {
  my $self = shift;
  $self->debug(0);
  attr $self;

  # add tables
  my $name = $self->get_db($DBH);
  my $sth  = $DBH->prepare(qq{SHOW TABLES FROM $name}) || die($DBH->errstr);
  my $rv   = $sth->execute                             || die($sth->errstr);
  my(@tables,@byname);
  while ( ($name) = $sth->fetchrow_array ) {
    my $table = DbFramework::Table->new($name,undef,undef,$DBH);
    push(@tables,$table->init_db_metadata);
  }
  $self->collects_table_l(\@tables);
  for ( @tables ) { push(@byname,($_->name,$_)) }
  $self->collects_table_h(\@byname);

  # add foreign keys
  for my $table ( @tables ) {
    my(%keys,@row,$table_name);
    $table_name = $table->name;
    print STDERR "looking for foreign keys in table $table_name\n" if $_DEBUG;
    $sth = $DBH->prepare(qq{SHOW KEYS FROM $table_name}) || die($DBH->errstr);
    $rv = $sth->execute                                  || die($sth->errstr);
    while ( @row = $sth->fetchrow_array ) { push(@{$keys{$row[2]}},$row[4]) }
    for ( keys(%keys) ) {
      if ( $_ =~ /^f_/i ) {              # foreign key
	my($pk_table_name) = $_ =~ /^f_(.*)$/;
	print STDERR "table = $table_name, \$pk_table_name = $pk_table_name\n" if $_DEBUG;
	my($pk_table) = $self->collects_table_h_byname($pk_table_name);
	die "Can't find table '$pk_table_name' while processing foreign key '$_' in table '$table_name'" if $pk_table eq '';
	my @fk_attributes = $table->get_attributes(@{$keys{$_}});
	my $fk = new DbFramework::ForeignKey($pk_table_name,\@fk_attributes,
					     $pk_table->is_identified_by
					    );

	$fk->belongs_to($table);
	$table->has_foreign_keys_l_add($fk);                     # by number
	$table->has_foreign_keys_h_add({$pk_table_name => $fk}); # by name
	$pk_table->is_identified_by->incorporates($fk);          # pk ref
      }
    }
    $table->validate_foreign_keys;
    # default templates need updating after setting foreign keys
    $table->_templates;
  }

  my $rc = $sth->finish;
  return $self;
}

#------------------------------------------------------------------------------

=head1 SEE ALSO

L<DbFramework::Table> and L<DbFramework::Util>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Once upon a time, on a CPAN mirror not so far away there was
B<Msql::RDBMS>.

=cut

1;
