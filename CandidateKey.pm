package DbFramework::CandidateKey;
use strict;
use base qw(DbFramework::Key);
use Alias;
use vars qw( $NAME );
use Carp;

# CLASS DATA

my %fields = (
              # CandidateKey 0:N Incorporates 0:N ForeignKey
              INCORPORATES => undef,
);

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

#=head1 CLASS METHODS

#=head2 new(\@columns)

#Create a new B<DbFramework::PrimaryKey> object.  I<@columns> is a list
#of B<DbFramework::Column> objects.

#=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless($class->SUPER::new(shift),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;
  
  return $self;
}

##-----------------------------------------------------------------------------

#=head2 create_ddl()

#Returns a string which can be used in an SQL 'CREATE TABLE' statement
#to create the primary key.

#=cut

sub create_ddl {
  my $self = attr shift;
  return "PRIMARY KEY(" . join(',',@{$self->column_names}) . ")";
}

##-----------------------------------------------------------------------------

sub DESTROY {
  my $DEBUG = 0;
  my $self  = attr shift;
  carp "Destroying $self" if $DEBUG;
}

##-----------------------------------------------------------------------------

1;
