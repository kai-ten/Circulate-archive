# Setup your environment

This guide covers how to begin interacting with the database via the CLI.

<br>

There are two clients:

- CockroachCloudCLI
    - Used to manage the cluster itself (e.g. create new Cluster, create users, etc)
- CockroachDB Client
    - Used to manage the database (e.g. schema creation, table creation, etc)

<br />

## Set up

1. Follow this guide to install CockroachDB CLI [CDB CLI](https://www.cockroachlabs.com/blog/cockroachdb-ccloud-cli/)
1. In the CDB console, get the database Connection string and connect
    - e.g. for CockroachCloud CLI. `ccloud cluster sql bamboo-scylla -u <ENTER-SQL-USER-Name> -p <ENTER-SQL-USER-PASSWORD>`
    - e.g. for CockroachDB Client. `cockroach sql --url "postgresql://<ENTER-SQL-USER-Name>@bamboo-scylla-7752.7tt.cockroachlabs.cloud:26257/Circulate?sslmode=verify-full"`
1. Get familiar with the possible commands [CDB Commands](https://www.cockroachlabs.com/docs/v22.2/cockroach-commands.html)
1. Read the SQL guide - [SQL Guide](https://www.cockroachlabs.com/docs/v22.2/cockroach-sql#prerequisites)


ccloud cluster sql bamboo-scylla -u kai -p -DH0WZpUL6PajyBSa9oqLg -d Circulate

cockroach sql \
--url "postgresql://kai:-DH0WZpUL6PajyBSa9oqLg@bamboo-scylla-7752.7tt.cockroachlabs.cloud:26257/Circulate?sslmode=verify-full"


## Commands for CockroachCloud CLI

[Full Documentation](https://www.cockroachlabs.com/docs/stable/cockroach-sql.html)

Welcome to the CockroachDB SQL shell.

`All statements must be terminated by a semicolon.`

To exit, type: `\q`.

Enter \? for a brief introduction.

```

General
  \q, quit, exit    exit the shell (Ctrl+C/Ctrl+D also supported).

Help
  \? or "help"      print this help.
  \h [NAME]         help on syntax of SQL commands.
  \hf [NAME]        help on SQL built-in functions.

Query Buffer
  \p                during a multi-line statement, show the SQL entered so far.
  \r                during a multi-line statement, erase all the SQL entered so far.
  \| CMD            run an external command and run its output as SQL statements.

Connection
  \c, \connect {[DB] [USER] [HOST] [PORT] | [URL]}
                    connect to a server or print the current connection URL.
                    (Omitted values reuse previous parameters. Use '-' to skip a field.)

Input/Output
  \echo [STRING]    write the provided string to standard output.
  \i                execute commands from the specified file.
  \ir               as \i, but relative to the location of the current script.

Informational
  \l                list all databases in the CockroachDB cluster.
  \dt               show the tables of the current schema in the current database.
  \dT               show the user defined types of the current database.
  \du [USER]        list the specified user, or list the users for all databases if no user is specified.
  \d [TABLE]        show details about columns in the specified table, or alias for '\dt' if no table is specified.
  \dd TABLE         show details about constraints on the specified table.

Formatting
  \x [on|off]       toggle records display format.

Operating System
  \! CMD            run an external command and print its results on standard output.

Configuration
  \set [NAME]       set a client-side flag or (without argument) print the current settings.
  \unset NAME       unset a flag.

Statement diagnostics
  \statement-diag list                               list available bundles.
  \statement-diag download <bundle-id> [<filename>]  download bundle.

```


## Commands for CockroachDB Client

```
  \q, quit, exit    exit the shell (Ctrl+C/Ctrl+D also supported).

Help
  \? or "help"      print this help.
  \h [NAME]         help on syntax of SQL commands.
  \hf [NAME]        help on SQL built-in functions.

Query Buffer
  \p                during a multi-line statement, show the SQL entered so far.
  \r                during a multi-line statement, erase all the SQL entered so far.
  \| CMD            run an external command and run its output as SQL statements.

Connection
  \c, \connect {[DB] [USER] [HOST] [PORT] | [URL]}
                    connect to a server or print the current connection URL.
                    (Omitted values reuse previous parameters. Use '-' to skip a field.)
  \password [USERNAME]
                    securely change the password for a user

Input/Output
  \echo [STRING]    write the provided string to standard output.
  \i                execute commands from the specified file.
  \ir               as \i, but relative to the location of the current script.
  \o [FILE]         send all query results to the specified file.
  \qecho [STRING]   write the provided string to the query output stream (see \o).

Informational
  \l                list all databases in the CockroachDB cluster.
  \dt               show the tables of the current schema in the current database.
  \dT               show the user defined types of the current database.
  \du [USER]        list the specified user, or list the users for all databases if no user is specified.
  \d [TABLE]        show details about columns in the specified table, or alias for '\dt' if no table is specified.
  \dd TABLE         show details about constraints on the specified table.
  \df               show the functions that are defined in the current database.

Formatting
  \x [on|off]       toggle records display format.

Operating System
  \! CMD            run an external command and print its results on standard output.

Configuration
  \set [NAME]       set a client-side flag or (without argument) print the current settings.
  \unset NAME       unset a flag.

Statement diagnostics
  \statement-diag list                               list available bundles.
  \statement-diag download <bundle-id> [<filename>]  download bundle.


More documentation about our SQL dialect and the CLI shell is available online:
https://www.cockroachlabs.com/docs/v22.2/sql-statements.html
https://www.cockroachlabs.com/docs/v22.2/use-the-built-in-sql-client.html
```

