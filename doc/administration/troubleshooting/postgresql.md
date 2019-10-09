---
type: reference
---

# PostgreSQL

This page is useful information about PostgreSQL that the GitLab Support
Team sometimes uses while troubleshooting. GitLab is making this public, so that anyone
can make use of the Support team's collected knowledge.

CAUTION: **Caution:** Some procedures documented here may break your GitLab instance. Use at your own risk.

If you are on a [paid tier](https://about.gitlab.com/pricing/) and are not sure how
to use these commands, it is best to [contact Support](https://about.gitlab.com/support/)
and they will assist you with any issues you are having.

## Other GitLab PostgreSQL documentation

### Procedures

- [Connect to the PostgreSQL console.](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)

- [Omnibus database procedures](https://docs.gitlab.com/omnibus/settings/database.html) including
  - SSL: enabling, disabling, and verifying.
  - Enabling Write Ahead Log (WAL) archiving.
  - Using an external (non-Omnibus) PostgreSQL installation; and backing it up.
  - Listening on TCP/IP as well as or instead of sockets.
  - Storing data in another location.
  - Destructively reseeding the GitLab database.
  - Guidance around updating packaged PostgreSQL, including how to stop it happening automatically.

- [More about external PostgreSQL](/ee/administration/external_database.html)

- [Running GEO with external PostgreSQL](/ee/administration/geo/replication/external_database.html)

- [Upgrades when running PostgreSQL configured for HA.](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-gitlab-ha-cluster)

- Consuming PostgreSQL from [within CI runners](/ee/ci/services/postgres.html)

- [Using Slony to update PostgreSQL](/ee/update/upgrading_postgresql_using_slony.html)
  - Uses replication to handle PostgreSQL upgrades - providing the schemas are the same.
  - Reduces downtime to a short window for swinging over to the newer vewrsion.

- Managing Omnibus PostgreSQL versions [from the development docs](https://docs.gitlab.com/omnibus/development/managing-postgresql-versions.html)

- [PostgreSQL scaling and HA](/ee/administration/high_availability/database.html)
  - including [troubleshooting](/ee/administration/high_availability/database.html#troubleshooting) gitlab-ctl repmgr-check-master and pgbouncer errors

- [Developer database documentation](/ee/development/README.html#database-guides) - some of which is absolutely not for production use. Including:
  - understanding EXPLAIN plans

### Troubleshooting/Fixes

- [GitLab database requirements](/ee/install/requirements.html#database) including
  - Support for MySQL was removed in GitLab 12.1; [migrate to PostgreSQL](/ee/update/mysql_to_postgresql.html)
  - required extension pg_trgm
  - required extension postgres_fdw for Geo

- Errors like this in the production/sidekiq log;  see: [Set default_transaction_isolation into read committed](https://docs.gitlab.com/omnibus/settings/database.html#set-default_transaction_isolation-into-read-committed)

```
ActiveRecord::StatementInvalid PG::TRSerializationFailure: ERROR:  could not serialize access due to concurrent update
```

- PostgreSQL HA - [replication slot errors](https://docs.gitlab.com/omnibus/settings/database.html#troubleshooting-upgrades-in-an-ha-cluster)

```
pg_basebackup: could not create temporary replication slot "pg_basebackup_12345": ERROR:  all replication slots are in use
HINT:  Free one or increase max_replication_slots.
```

- GEO [replication errors](/ee/administration/geo/replication/troubleshooting.html#fixing-replication-errors) including:

```
ERROR: replication slots can only be used if max_replication_slots > 0

FATAL: could not start WAL streaming: ERROR: replication slot “geo_secondary_my_domain_com” does not exist

Command exceeded allowed execution time

PANIC: could not write to file ‘pg_xlog/xlogtemp.123’: No space left on device
```

- [Checking GEO configuration](/ee/administration/geo/replication/troubleshooting.html#checking-configuration) including
  - reconfiguring hosts/ports
  - checking and fixing user/password mappings

- [Common GEO errors](/ee/administration/geo/replication/troubleshooting.html#fixing-common-errors)
