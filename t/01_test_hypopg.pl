
# Copyright (c) 2021-2024, PostgreSQL Global Development Group

# Test pg_hint_plan with hypopg

use strict;
use warnings FATAL => 'all';

use PostgreSQL::Test::Cluster;
use PostgreSQL::Test::Utils;

use Test::More;

my $node = PostgreSQL::Test::Cluster->new('hypopg_test');
$node->init;
$node->append_conf('postgresql.conf', 'shared_preload_libraries = \'pg_hint_plan,hypopg\'');
$node->start;

my $is_hypopg = $node->safe_psql('postgres', q(SELECT setting FROM pg_settings WHERE name = 'shared_preload_libraries' AND SETTING LIKE '%hypopg%';));

isnt( $is_hypopg, '', 'Extension "hypopg" is loaded via shared_preload_library');

$node->safe_psql('postgres', q(CREATE extension hypopg));
$node->safe_psql('postgres', q(LOAD 'pg_hint_plan'));
$node->safe_psql('postgres', q(CREATE TABLE t1(a INT, b INT, c INT)));
$node->safe_psql('postgres', q(CREATE INDEX ON t1 (a)));
$node->safe_psql('postgres', q(SELECT hypopg_create_index('CREATE INDEX ON t1(b)')));

my $plan_result = $node->safe_psql('postgres', q(EXPLAIN SELECT/*+ indexscan(t1 t1_a_idx)*/ FROM t1 WHERe a = 3 AND b =4));
note 'plan_result is:', $plan_result;

isnt( $plan_result, '', 'Explain plan works, no coredump');

$node->stop;
done_testing();

