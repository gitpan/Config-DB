use Test::More tests => 18;

my $dbh = DBI->connect( 'DBI:DBM:', undef, undef );

$dbh->do( "DROP TABLE cfg" );
$dbh->do( "CREATE TABLE cfg ( ckey INTEGER, cvalue INTEGER )" );
$dbh->do( "INSERT INTO cfg VALUES ( 1000, 1 )" );
$dbh->do( "INSERT INTO cfg VALUES ( 2000, 2 )" );
$dbh->do( "INSERT INTO cfg VALUES ( 3000, 3 )" );

BEGIN { use_ok 'Config::DB' }
require_ok( 'Config::DB' );

my $cfg = Config::DB->new( connect => [ 'DBI:DBM:', undef, undef ], tables => { cfg => 'ckey' } );

eval { $cfg->read };
is( $@, '', 'ok call' );

eval { $cfg->get; };
like( $@, qr{^Config::DB::get: missing table parameter at t/03_get.t line \d+$}, 'missing table parameter' );

eval { $cfg->get( 'notable' ); };
like( $@, qr{^Config::DB::get: missing key parameter at t/03_get.t line \d+$}, 'missing key parameter' );

eval { $cfg->get( 'notable', 10 ); };
like( $@, qr{^Config::DB::get: unknown configuration table 'notable' at t/03_get.t line \d+$}, 'missing table' );

eval { $cfg->get( 'cfg', 10 ); };
like( $@, qr{^Config::DB::get: missing key '10' in configuration table 'cfg' at t/03_get.t line \d+$}, 'missing key' );

eval { $cfg->get( 'cfg', 1000, 'nofield' ); };
like( $@, qr{^Config::DB::get: unknown field 'nofield' for configuration table 'cfg' at t/03_get.t line \d+$}, 'missing field' );

is( $cfg->get( 'cfg', 2000, 'cvalue' ), 2, 'value get' );

my $h = $cfg->get( 'cfg', 3000 );
isa_ok( $h, 'HASH', 'hash get HASH' );
is( $h->{ckey}, 3000, 'hash get 1' );
is( $h->{cvalue}, 3, 'hash get 2' );

$cfg = Config::DB->new( connect => [ 'DBI:DBM:', undef, undef ], tables => { cfg => 'ckey + cvalue' } );

is( $cfg->get( 'cfg', 2002, 'cvalue' ), 2, 'exotic get' );

eval { $cfg->nomethod; };
like( $@, qr{^Can't locate object method "nomethod" via package "Config::DB" at t/03_get.t line \d+$}, 'AUTOLOAD error' );

eval { $cfg->_notable( 10 ); };
like( $@, qr{^Config::DB::get: unknown configuration table 'notable' at t/03_get.t line \d+$}, 'AUTOLOAD missing table' );

eval { $cfg->_cfg( 3000 ); };
like( $@, qr{^Config::DB::get: missing key '3000' in configuration table 'cfg' at t/03_get.t line \d+$}, 'AUTOLOAD missing key' );

is( $cfg->get( 'cfg', 3003, 'cvalue' ), $cfg->_cfg( 3003, 'cvalue' ), 'AUTOLOAD 1' );
is( $cfg->_cfg( 1001 )->{ckey}, 1000, 'AUTOLOAD 2' );
