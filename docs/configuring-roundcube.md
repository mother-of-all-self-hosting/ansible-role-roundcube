<!--
SPDX-FileCopyrightText: 2020 Aaron Raimist
SPDX-FileCopyrightText: 2020 Chris van Dijk
SPDX-FileCopyrightText: 2020 Dominik Zajac
SPDX-FileCopyrightText: 2020 Mickaël Cornière
SPDX-FileCopyrightText: 2020-2024 MDAD project contributors
SPDX-FileCopyrightText: 2020-2024 Slavi Pantaleev
SPDX-FileCopyrightText: 2022 François Darveau
SPDX-FileCopyrightText: 2022 Julian Foad
SPDX-FileCopyrightText: 2022 Warren Bailey
SPDX-FileCopyrightText: 2023 Antonis Christofides
SPDX-FileCopyrightText: 2023 Felix Stupp
SPDX-FileCopyrightText: 2023 Julian-Samuel Gebühr
SPDX-FileCopyrightText: 2023 Pierre 'McFly' Marty
SPDX-FileCopyrightText: 2024 Thomas Miceli
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Setting up Roundcube

This is an [Ansible](https://www.ansible.com/) role which installs [Roundcube](https://roundcube.net/) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

Roundcube is a browser-based multilingual IMAP client with an application-like user interface. It provides full functionality you expect from an email client, including MIME support, address book, folder manipulation, message searching and spell checking.

See the project's [documentation](https://docs.roundcube.net/) to learn what Roundcube does and why it might be useful to you.

>[!NOTE]
> The role is configured to install nonroot container image, and therefore a couple of functions are not available without adding adjustments. See [this section](https://github.com/roundcube/roundcubemail-docker/blob/master/README.md#nonroot-image) on the official documentation for details.

## Prerequisites

To run a Roundcube instance it is necessary to prepare a database. You can use a [MySQL](https://www.mysql.com/) compatible database server, [Postgres](https://www.postgresql.org/), or [SQLite](https://www.sqlite.org/). The SQLite database file will be automatically created by the service if it is enabled.

If you are looking for Ansible roles for a MySQL compatible server or Postgres, you can check out [ansible-role-mariadb](https://github.com/mother-of-all-self-hosting/ansible-role-mariadb) and [ansible-role-postgres](https://github.com/mother-of-all-self-hosting/ansible-role-postgres), both of which are maintained by the [Mother-of-All-Self-Hosting (MASH)](https://github.com/mother-of-all-self-hosting) team.

## Adjusting the playbook configuration

To enable Roundcube with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# roundcube                                                            #
#                                                                      #
########################################################################

roundcube_enabled: true

########################################################################
#                                                                      #
# /roundcube                                                           #
#                                                                      #
########################################################################
```

### Set the hostname

To enable Roundcube you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
roundcube_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

### Specify database

It is necessary to select database used by Roundcube from a MySQL compatible database, Postgres, and SQLite.

To use Postgres, add the following configuration to your `vars.yml` file:

```yaml
roundcube_database_type: postgres
```

Set `mysql` to use a MySQL compatible database and `sqlite` to use SQLite, respectively. The SQLite database is stored in the directory specified with `roundcube_database_path`.

For other settings, check variables such as `roundcube_database_*` on [`defaults/main.yml`](../defaults/main.yml).

### Specify IMAP and SMTP servers

It is also necessary to specify the hostname of IMAP and SMTP servers for the Roundcube instance to connect by adding the following configuration to your `vars.yml` file:

```yaml
roundcube_environment_variables_default_imap_host: YOUR_IMAP_SERVER_HOSTNAME_HERE

roundcube_environment_variables_smtp_server: YOUR_SMTP_SERVER_HOSTNAME_HERE
```

If the connections to them are encrypted, make sure to add `tls://` (STARTTLS) or `ssl://` (SSL/TLS) as prefix to those hostnames.

The port number of them can be specified with variables as below:

```yaml
# Specify IMAP port number
roundcube_environment_variables_default_imap_port: 143

# Specify SMTP port number
roundcube_environment_variables_smtp_port: 587
```

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `roundcube_environment_variables_additional_variables` variable

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, Roundcube becomes available at the specified hostname like `https://example.com`.

To get started, open the URL with a web browser, and log in to the instance with the username and password, which are the same ones for your IMAP server.

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu roundcube` (or how you/your playbook named the service, e.g. `mash-roundcube`).
