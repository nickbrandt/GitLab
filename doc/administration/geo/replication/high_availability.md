# Geo High Availability

This document describes a minimal reference architecture for running Geo
in a high availability configuration. If your HA setup differs from the one
described, it is possible to adapt these instructions to your needs.

## Architecture overview

![Geo HA Diagram](../../img/high_availability/geo-ha-diagram.png)

_[diagram source - gitlab employees only][diagram-source]_

The topology above assumes that the primary and secondary Geo clusters
are located in two separate locations, on their own virtual network
with private IP addresses. The network is configured such that all machines within
one geographic location can communicate with each other using their private IP addresses.
The IP addresses given are examples and may be different depending on the
network topology of your deployment.

The only external way to access the two Geo deployments is by HTTPS at
`gitlab.us.example.com` and `gitlab.eu.example.com` in the example above.

> **Note:** The primary and secondary Geo deployments must be able to
  communicate to each other over HTTPS.

## Redis and PostgreSQL High Availability

The primary and secondary Redis and PostgreSQL should be configured
for high availability. Because of the additional complexity involved
in setting up this configuration for PostgreSQL and Redis
it is not covered by this Geo HA documentation.

For more information about setting up a highly available PostgreSQL cluster and Redis cluster using the omnibus package see the high availability documentation for
[PostgreSQL][postgresql-ha] and [Redis][redis-ha], respectively.

NOTE: **Note:**
It is possible to use cloud hosted services for PostgreSQL and Redis but this is beyond the scope of this document.

## Prerequisites: A working GitLab HA cluster

This cluster will serve as the Geo Primary. Use the
[GitLab HA documentation][gitlab-ha] to set this up.

## Configure the working cluster to be a Geo Primary

### Step 1: Configure the Geo Primary Frontend Servers

1. Edit `/etc/gitlab/gitlab.rb` and add the following:

    ```ruby
    ##
    ## Enable the Geo primary role
    ##
    roles ['geo_primary_role']

    ##
    ## Disable automatic migrations
    ##
    gitlab_rails['auto_migrate'] = false
    ```

After making these changes, [reconfigure GitLab][gitlab-reconfigure] so that they take effect.

NOTE: **Note:** PostgreSQL and Redis should have already been disabled on the
application servers and the connections configured, during normal GitLab
HA set up. See documentation for
[PostgreSQL][postgresql-ha-configuring-application-nodes] and
[Redis][redis-ha-configuring-the-application-nodes]

The Geo Primary database will require modification later, as part of
[Step 2 of Configure a Geo Secondary][step-2-of-configure-a-geo-secondary].

## Configure a Geo Secondary

A Geo Secondary cluster is similar to any other GitLab HA cluster, with two
major differences:

1. The main PostgreSQL database is a read-only replica of the Geo Primary's
   PostgreSQL database.
1. There is also a single PostgreSQL database per Geo Secondary cluster, called
   the "tracking database", which tracks the sync state of various resources.

So, we will set up the HA components one-by-one, and include deviations from
the normal HA setup.

### Step 1: Configure the Redis and NFS services on the Geo Secondary

Configure the following services, again using the non-Geo, HA documentation:

* [Redis][redis-ha] for high availability.
* [NFS Server][nfs-ha] which will store data that is synchronized from the Geo primary.

### Step 2: Configure the main read-only replica PostgreSQL database on the Geo Secondary

NOTE: **Note:** This documentation assumes the DB will be run on only a single
machine, rather than as a PostgreSQL cluster.

Configure the [secondary Geo PostgreSQL database][database] as a read-only
secondary of the primary Geo PostgreSQL database. Be sure to follow the
[External PostgreSQL instances][external-postgresql] section.

### Step 3: Configure the tracking database on the Geo Secondary

NOTE: **Note:** This documentation assumes the tracking DB will be run on only a
single machine, rather than as a PostgreSQL cluster.

Configure the [Geo tracking database][tracking-database].

### Step 4: Configure the Frontend Application servers on the Geo Secondary

In the architecture overview, there are two machines running the GitLab
application services. These services are enabled selectively in the
configuration.

Configure the application servers following [Configuring GitLab for HA][app-ha],
then make the following modifications:

1. Edit `/etc/gitlab/gitlab.rb` on each application server in the secondary
   cluster, and add the following:

    ```ruby
    ##
    ## Enable the Geo secondary role
    ##
    roles ['geo_secondary_role', 'application_role']

    ##
    ## Disable automatic migrations
    ##
    gitlab_rails['auto_migrate'] = false

    ##
    ## Configure the connection to the tracking DB. And disable application
    ## servers from running tracking databases.
    ##
    geo_secondary['db_host'] = '10.1.4.1'
    geo_secondary['db_password'] = 'plaintext Geo tracking DB password'
    geo_postgresql['enable'] = false

    ##
    ## Configure connection to the streaming replica database, if you haven't
    ## already
    ##
    gitlab_rails['db_host'] = '10.1.3.1'
    gitlab_rails['db_password'] = 'plaintext DB password'

    ##
    ## Configure connection to Redis, if you haven't already
    ##
    gitlab_rails['redis_host'] = '10.1.2.1'
    gitlab_rails['redis_password'] = 'Redis password'

    ##
    ## If you are using custom users not managed by Omnibus, you need to specify
    ## UIDs and GIDs like below, and ensure they match between servers in a
    ## cluster to avoid permissions issues
    ##
    user['uid'] = 9000
    user['gid'] = 9000
    web_server['uid'] = 9001
    web_server['gid'] = 9001
    registry['uid'] = 9002
    registry['gid'] = 9002
    ```

NOTE: **Note:**
If you had set up PostgreSQL cluster using the omnibus package and you had set
up `postgresql['sql_user_password'] = 'md5 digest of secret'` setting, keep in
mind that `gitlab_rails['db_password']` and `geo_secondary['db_password']`
mentioned above contains the plaintext passwords. This is used to let the Rails
servers connect to the databases.

NOTE: **Note:**
Make sure that current node IP is listed in `postgresql['md5_auth_cidr_addresses']` setting of your remote database.

After making these changes [Reconfigure GitLab][gitlab-reconfigure] so that they take effect.

On the secondary the following GitLab frontend services will be enabled:

* geo-logcursor
* gitlab-pages
* gitlab-workhorse
* logrotate
* nginx
* registry
* remote-syslog
* sidekiq
* unicorn

Verify these services by running `sudo gitlab-ctl status` on the frontend
application servers.

### Step 5: Set up the LoadBalancer for the Geo Secondary

In this topology there will need to be a load balancers at each geographical
location to route traffic to the application servers.

See the [Load Balancer for GitLab HA][load-balancer-ha]
documentation for more information.

[diagram-source]: https://docs.google.com/drawings/d/1z0VlizKiLNXVVVaERFwgsIOuEgjcUqDTWPdQYsE7Z4c/edit
[gitlab-reconfigure]: ../../restart_gitlab.md#omnibus-gitlab-reconfigure
[redis-ha]: ../../high_availability/redis.md
[redis-ha-configuring-the-application-nodes]: ../../high_availability/redis.md#example-configuration-for-the-gitlab-application
[postgresql-ha]: ../../high_availability/database.md
[postgresql-ha-configuring-application-nodes]: ../../high_availability/database.md#configuring-the-application-nodes
[nfs-ha]: ../../high_availability/nfs.md
[load-balancer-ha]: ../../high_availability/load_balancer.md
[database]: database.md
[tracking-database]: database.md#tracking-database-for-the-secondary-nodes
[external-postgresql]: database.md#external-postgresql-instances
[gitlab-rb-template]: https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template
[gitlab-ha]: ../../high_availability/README.md
[app-ha]: ../../high_availability/gitlab.md
[step-2-of-configure-a-geo-secondary]: #step-2-configure-the-main-read-only-replica-postgresql-database-on-the-geo-secondary
