# Vault Oracle Database Secrets Engine

Oracle is one of the supported plugins for the database secrets engine. The Oracle Database Secrets Engine plugin generates database credentials dynamically based on configured roles for the Oracle database.

## Perquisites

### Oracle Database Server

Let's deploy an Oracle server if you don't already have one running.

In our example, we will deploy one using Docker. This document doesn't cover the installation of Docker but expects that you have it already installed.

Please note that you will need to log into Docker Hub and license the developer edition of Oracle Enterprise Database Server. For more information on running Oracle in Docker, please see https://hub.docker.com/_/oracle-database-enterprise-edition.

Let's pull the docker image for Oracle Database Server.

```
docker pull store/oracle/database-enterprise:12.2.0.1
```

Let's run the Oracle Database Server.
```
docker run \
  -d \
  -it \
  --name oracledb \
  -p 127.0.0.1:1521:1521 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  store/oracle/database-enterprise:12.2.0.1
```

### Oracle Client Library

We will need the Oracle Instant Client Package. The version required correlates to the version of the Oracle library used in compiling the Vault Oracle plugin. If you are using build version 0.1.6 from releases.hashicorp.com, as detailed below, you will need versiion 19.6.0.0 of the Oracle Instant Client Package.

#### Download

To download the Oracle Instant Client Package, please visit:

https://www.oracle.com/database/technologies/instant-client/downloads.html

Please note that you will need an Oracle account in order to download the package.

The direct download to the Linux 64-bit package used in this example is:

https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basic-linux.x64-19.6.0.0.0dbru.zip

#### Install

Per the installation instructions on the Oracle Instant Client download page, install the `libaio1` and `unzip` packages.

```
apt-get update -y && \
  apt install -y \
    unzip
    libaio1

    unzip -d /usr/local instantclient-basic-linux.x64-19.6.0.0.0dbru.zip && \
    echo /usr/local/instantclient_19_6 > /etc/ld.so.conf.d/oracle-instantclient.conf  && \
    ldconfig && \

```

### Vault Oracle Plugin

#### Download

The Oracle database plugin is not bundled with Vault and can be found for Linux 64-bit architecture at:

https://releases.hashicorp.com/vault-plugin-database-oracle/

The path to the Linux 64-bit build of version 0.1.6 of the plugin used in this example is:

https://releases.hashicorp.com/vault-plugin-database-oracle/0.1.6/vault-plugin-database-oracle_0.1.6_linux_amd64.zip

#### Compile

You may also clone the github repo and compile the plugin for your architecture via:

https://github.com/hashicorp/vault-plugin-database-oracle

Details for compiling the plugin are not covered in this document.

#### Install

Once you download or compile the plugin, place it in Vault's plugin directory.

### Vault config

The Vault config must include the path to the plugin directory:

```
plugin_directory="/data/vault/plugins"
```

### Environment variables

Let's define some environment variables to facilitate our task.

```
export ORACLE_PATH_PREFIX="<prefix>"
export VAULT_PLUGIN_DIRECTORY=<Vault plugin directory defined above>"
```

For example:
```
export ORACLE_PATH_PREFIX="oracle_vault"
export VAULT_PLUGIN_DIRECTORY="/data/vault/plugins"
```

### Enable support for database secrets in Vault
Let's enable support for database secrets in Vault.

```
vault secrets disable ${ORACLE_PATH_PREFIX}

vault secrets enable -path=${ORACLE_PATH_PREFIX} database
```

### Register the plugin.

In order to register the plugin, we must calculate the sha256 sum of the plugin:

```
export ORACLE_PLUGIN_SHA256SUM=$(sha256sum ${VAULT_PLUGIN_DIRECTORY}/vault-plugin-database-oracle | awk '{print $1}')
```

We can see the sha256 sum:

```
echo ${ORACLE_PLUGIN_SHA256SUM}
```

And then we can register the plugin:
```
vault write \
  sys/plugins/catalog/database/oracle-database-plugin \
  sha256="${ORACLE_PLUGIN_SHA256SUM}" \
  command=vault-plugin-database-oracle
```

### Configure the plugin.
Let's configure the plugin with the connection information for our Oracle database server's connection string.
```
vault write \
  ${ORACLE_PATH_PREFIX}/config/my-oracle-database1 \
  plugin_name=oracle-database-plugin \
  connection_url="sys/Oradoc_db1@127.0.0.1:1521/ORCLCDB.localdomain?as=sysdba" \
  allowed_roles="my-oracle-role-1"
```

### Configure the role.
Let's configure the role `my-oracle-role-1` that maps a name in Vault to an SQL statement to execute to create the database credential
```
vault write \
  ${ORACLE_PATH_PREFIX}/roles/my-oracle-role-1 \
  db_name=my-oracle-database1 \
  creation_statements="alter session set \"_ORACLE_SCRIPT\"=true;  CREATE USER {{name}} IDENTIFIED BY {{password}}; GRANT CONNECT TO {{name}}; GRANT CREATE SESSION TO {{name}};" \
  default_ttl="1h" \
  max_ttl="24h"
```

### Define a policy for access to this role
Let's create a policy that will be provisioned to clients that need to retrieve credentials for our Oracle database via this role.
```
vault policy write my-oracle-db_policy -<<EOF
# my-oracle-db_policy
path "${ORACLE_PATH_PREFIX}/creds/my-oracle-role-1" {
  capabilities = ["read"]
}
EOF
```

Let's take a look at our policy.

```
vault policy read my-oracle-db_policy
```

### Get dynamic credentials
Let's generate a new set of, just-in-time dynamic credentials for Oracle.
```
vault read ${ORACLE_PATH_PREFIX}/creds/my-oracle-role-1
```

For examle:
```
vault read ${ORACLE_PATH_PREFIX}/creds/my-oracle-role-1
Key                Value
---                -----
lease_id           oracle_vault/creds/my-oracle-role-1/M93xBhN4YkpGsLQZnVTjOTOj
lease_duration     1h
lease_renewable    true
password           A1a_kxkS3G26N3AqjRfL
username           v_root_my_oracl_8wwobu18nt0eba
```

Run this command again, and you will notice that we get a different set of credentials.

```
vault read ${ORACLE_PATH_PREFIX}/creds/my-oracle-role-1
Key                Value
---                -----
lease_id           oracle_vault/creds/my-oracle-role-1/IRu7BhlHaFak5eITsufAQcjG
lease_duration     1h
lease_renewable    true
password           A1a_6oPCb3CuoSdXQj5f
username           v_root_my_oracl_tx6gqg0whbagks
```

Let's get the username, password and lease_id and store them into variables for use.

```
read ORACLE_DYNAMIC_USER ORACLE_DYNAMIC_PASSWORD < <(echo $(vault read -format=json ${ORACLE_PATH_PREFIX}/creds/my-oracle-role-1 | jq -r '.data.username, .data.password') )

echo ${ORACLE_DYNAMIC_USER}
echo ${ORACLE_DYNAMIC_PASSWORD}
```

### Test dynamic credentials
Let's log into our Oracle database server using the credentials we retrieved.

```
sqlplus <username>/<password>
```

Because we're running Oracle inside a docker container, let's echo out the command we need to run once we exec into the container.
```
echo "sqlplus ${ORACLE_DYNAMIC_USER}/${ORACLE_DYNAMIC_PASSWORD}"
```

Let's exec into the container:
```
docker exec -it oracledb /bin/bash
```

Let's connect to our Oracle database using the command that was echoed above:
```
sqlplus <username>/<password>
```

Let's run a quick query.
```
select username as schema_name from sys.all_users order by username;
```

### Reference:

https://www.vaultproject.io/docs/secrets/databases/oracle/
