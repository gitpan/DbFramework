=head1 NAME

DbFramework::DataModel - Data Model class

=head1 SYNOPSIS

  use DbFramework::DataModel;
  $dm = new DbFramework::DataModel($name,$dsn,$user,$password);
  $dm->init_db_metadata;
  @tables = @{$dm->collects_table_l};
  %tables = %{$dm->collects_table_h};
  @tables = @{$dm->collects_table_h_byname(@tables)};
  $sql    = $dm->as_sql;
  $db     = $dm->db;
  $driver = $dm->driver;

=head1 DESCRIPTION

A B<DbFramework::DataModel> object represents a database schema.  It
can be initialised using the metadata provided by a DBI driver and a
catalog database (see L<DbFramework::Catalog>).

=head1 SUPERCLASSES

B<DbFramework::Util>

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
	      DRIVER => undef,
	      DB => undef,
);

###############################################################################
# CLASS METHODS
###############################################################################

=head1 CLASS METHODS

=head2 new($name,$dsn,$user,$password)

Create a new B<DbFramework::DataModel> object called I<$name>.
I<$dsn> is the DBI data source name associated with the data model.
I<$user> and I<$password> are optional arguments specifying the
username and password to use when connecting to the database.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;
  $self->name(shift);
  $self->dbh(DbFramework::Util::get_dbh(@_));
  #$self->init_db_metadata;
  # hack to record driver/db name until I confirm whether $dbh->{Name}
  # has been implemented for mSQL and Mysql
  $self->driver($_[0] =~ /DBI:(.*):/);
  $self->db($_[0] =~ /database=(\w+)/);
  return $self;
}

###############################################################################
# OBJECT METHODS
###############################################################################

=head1 OBJECT METHODS

A data model has a number of tables.  These tables can be accessed
using the methods I<COLLECTS_TABLE_L> and I<COLLECTS_TABLE_H>.  See
L<DbFramework::Util/AUTOLOAD()> for the accessor methods for these
attributes.

=head2 name($name)

If I<$name> is supplied sets the data model name.  Returns the data
model name.

=head2 db()

Returns the name of the database associated with the data model.

=head2 driver()

Returns the name of the driver associated with the data model.

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
from the database handle returned by dbh() and the catalog (see
L<DbFramework::Catalog>).  Foreign keys will be automatically
configured for tables in the data model but this method will die()
unless the number of attributes in each foreign and related primary
key match.

=cut

sub init_db_metadata {
  my $self = attr shift;

  # add tables
  my($table,@tables,@byname);
  for $table ( $DBH->tables ) {
    my $table = DbFramework::Table->new($table,undef,undef,$DBH,$self);
    push(@tables,$table->init_db_metadata);
  }
  $self->collects_table_l(\@tables);
  for ( @tables ) { push(@byname,($_->name,$_)) }
  $self->collects_table_h(\@byname);

  # add foreign keys
  my $c = new DbFramework::Catalog("DBI:mysql:database=$DbFramework::Catalog::db");
  $c->set_foreign_keys($self);

  return $self;
}

#------------------------------------------------------------------------------

=head1 SEE ALSO

L<DbFramework::Catalog>, L<DbFramework::Table> and
L<DbFramework::Util>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

This module was inspired by B<Msql::RDBMS>.

=cut

1;
