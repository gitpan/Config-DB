package Config::DB;

$Config::DB::VERSION = '0.0.1';

use strict;
use warnings;

use DBI;
use Carp;


sub new
{
        my ( $class, %pars ) = @_;
        my $self = { %pars, read => 0, values => {} };

	croak __PACKAGE__."::new: wrong call" if ! defined $class || $class eq '';

	eval { die if $class->check_Config_DB_hineritance ne 'check_Config_DB_hineritance'; };
	croak __PACKAGE__."::new: '$class' does not hinerit 'Config::DB'" if $@ ne '';

	croak __PACKAGE__."::new: missing 'connect' paramenter" if ! defined $self->{connect};
	croak __PACKAGE__."::new: 'connect' paramenter is not a reference to ARRAY" if ref $self->{connect} ne 'ARRAY';
	croak __PACKAGE__."::new: missing 'tables' paramenter" if ! defined $self->{tables};
	croak __PACKAGE__."::new: 'tables' paramenter is not a reference to HASH" if ref $self->{tables} ne 'HASH';
	croak __PACKAGE__."::new: no tables defined" if 0 == scalar keys %{ $self->{tables} };

        return bless $self, $class;
}

our $AUTOLOAD;

sub AUTOLOAD
{
	my ( $self, @pars ) = @_;
	my $name = $AUTOLOAD;

	$name =~ s/.*://;

	croak "Can't locate object method \"$name\" via package \"".__PACKAGE__.'"' unless $name =~ /^_/;

	$name =~ s/^_//;

	return $self->get( $name, @pars );
}

sub DESTROY
{
}

sub check_Config_DB_hineritance
{
	return 'check_Config_DB_hineritance';
}

sub get
{
	my ( $self, $table, $key, $field ) = @_;

	$self->read unless $self->{read};

	croak __PACKAGE__."::get: missing table parameter" unless defined $table;
	croak __PACKAGE__."::get: missing key parameter"   unless defined $key;
	croak __PACKAGE__."::get: unknown configuration table '$table'" unless exists $self->{values}->{$table};
	croak __PACKAGE__."::get: missing key '$key' in configuration table '$table'" unless exists $self->{values}->{$table}->{$key};

	return $self->{values}->{$table}->{$key} unless defined $field;

	croak __PACKAGE__."::get: unknown field '$field' for configuration table '$table'" unless exists $self->{values}->{$table}->{$key}->{$field};

	return $self->{values}->{$table}->{$key}->{$field};
}

sub read
{
	my ( $self ) = @_;
	my @connect  = @{ $self->{connect} };
	my %attr     = %{ $connect[3] || {} };
	my $dbh;

	$attr{PrintError} = 0;
	$attr{RaiseError} = 1;
	$connect[3]       = \%attr;

	eval { $dbh = DBI->connect( @connect ); };
	croak "$@\n".__PACKAGE__."::read: can't connect" if $@;

	foreach my $table ( keys %{ $self->{tables} } )
	{
		eval { $self->{values}->{$table} = $dbh->selectall_hashref( "SELECT $self->{tables}->{$table} AS dbcfg_key, $table.* FROM $table", 'dbcfg_key' ); };
		croak "$@\n".__PACKAGE__."::read: reading '$table' table" if $@;
	}

	$self->{read} = 1;
}


1;


__END__

=head1 NAME

Config::DB - DataBase Configuration module

=head1 SYNOPSIS

 use Config::DB;
 my %attr   = ();                                     # DBI::connect attributes HASH
 my @params = ( "DBI:...", 'usr', 'pwd', \%attr )     # DBI::connect parameters ARRAY
 my %tables = ( table1 => 'key1', table2 => 'key2' ); # table, key association
 my $cfg    = Config::DB->new( connect => \@params, tables => \%tables );
 $cfg->read;
 my $value1 = $cfg->get( 'table1', 1 );
 my $value2 = $cfg->get( 'table1', 2, 'field2' );
 my $value3 = $cfg->_table2( 3 );
 my $value4 = $cfg->_table2( 4, 'field4' );

=head1 DESCRIPTION

This module provides easy ways to make a one shot read of configuration database where tables have
an unique key. It requires a DB connection (though a DBI::connect parameter ARRAY) and the list of
the tables to read with relative key associated.

=head1 METHODS

=head2 new( connect => [ ... ], tables => { ... } )

It creates and returns the Config::DB objects itself gieving it configuration of configuration. The
connect parameter must be the reference to an ARRAY which is the DBI::connect parameters ARRAY, the
two attributes PrintError and RaiseError are overridden respectively with 0 and 1. The tables
parameter must be the reference to an HASH where every key is the name of a table to read and every
relative value is its unique key. It dies on error.

=head2 read

It reads all the configuration tables and closes DB connection. It returns no value. This method is
iplicitally called on first get call (explicit or by AUTOLOAD). It dies on error, so it is a good
idea to call it during application init.

=head2 get( $table_name, $key_value [ , $field_name ] )

It returns a configuration value or a configuration record. Parameter $table_name is the name of
the table containing requested value or record; parameter $key_value identifies the requested
record; without $field_name parameter a reference to an HASH containing all the record is returned,
if provided the method returns the value of that field as a SCALAR. It dies on missing table,
missing key value or missing field.

=head2 AUTOLOAD

A quicker syntax is offered: following calls are identical...

 my $value1 = $cfg->get( 'table1', 1 );
 my $value1 = $cfg->_table1( 1 );

... following calls are identical as well.

 my $value2 = $cfg->get( 'table2', 2 'field2' );
 my $value2 = $cfg->_table2( 2, 'field2' );

=head1 VERSION

0.0.1

=cut
