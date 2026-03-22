<!--
SPDX-FileCopyrightText: 2020 - 2024 MDAD project contributors
SPDX-FileCopyrightText: 2020 - 2024 Slavi Pantaleev
SPDX-FileCopyrightText: 2020 Aaron Raimist
SPDX-FileCopyrightText: 2020 Chris van Dijk
SPDX-FileCopyrightText: 2020 Dominik Zajac
SPDX-FileCopyrightText: 2020 Mickaël Cornière
SPDX-FileCopyrightText: 2022 François Darveau
SPDX-FileCopyrightText: 2022 Julian Foad
SPDX-FileCopyrightText: 2022 Warren Bailey
SPDX-FileCopyrightText: 2023 Antonis Christofides
SPDX-FileCopyrightText: 2023 Felix Stupp
SPDX-FileCopyrightText: 2023 Julian-Samuel Gebühr
SPDX-FileCopyrightText: 2023 Pierre 'McFly' Marty
SPDX-FileCopyrightText: 2024 Thomas Miceli
SPDX-FileCopyrightText: 2024 - 2025 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Setting up farmOS

This is an [Ansible](https://www.ansible.com/) role which installs [farmOS](https://farmos.org/) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

farmOS is a web-based free software for farm management, planning, and record keeping. It is developed by a community of farmers, developers, researchers, and organizations.

See the project's [documentation](https://farmos.org/guide/) to learn what farmOS does and why it might be useful to you.

## Prerequisites

To run a farmOS instance it is necessary to prepare a database. You can use a [MySQL](https://www.mysql.com/) compatible database server, [Postgres](https://www.postgresql.org/), or [SQLite](https://www.sqlite.org/). The SQLite database file will be automatically created by the service if it is enabled.

If you are looking for Ansible roles for a MySQL compatible server or Postgres, you can check out [ansible-role-mariadb](https://github.com/mother-of-all-self-hosting/ansible-role-mariadb) and [ansible-role-postgres](https://github.com/mother-of-all-self-hosting/ansible-role-postgres), both of which are maintained by the [Mother-of-All-Self-Hosting (MASH)](https://github.com/mother-of-all-self-hosting) team.

## Adjusting the playbook configuration

To enable farmOS with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# farmos                                                               #
#                                                                      #
########################################################################

farmos_enabled: true

########################################################################
#                                                                      #
# /farmos                                                              #
#                                                                      #
########################################################################
```

### Set the hostname

To enable farmOS you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
farmos_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

**Note**: hosting farmOS under a subpath (by configuring the `farmos_path_prefix` variable) does not seem to be possible due to farmOS's technical limitations.

>[!WARNING]
> Once the hostname is set, it cannot be changed easily as it involves adjusting configuration files.

### Specify database

It is necessary to select database used by farmOS from a MySQL compatible database, Postgres, and SQLite.

To use Postgres, add the following configuration to your `vars.yml` file:

```yaml
farmos_database_type: postgres
```

Set `mysql` to use a MySQL compatible database, and `sqlite` to use SQLite. The SQLite database is stored in the directory specified with `farmos_data_path`.

For other settings, check variables such as `farmos_database_*` on [`defaults/main.yml`](../defaults/main.yml).

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `farmos_environment_variables_additional_variables` variable

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, farmOS becomes available at the specified hostname like `https://example.com`.

To get started, open the URL with a web browser, and follow the set up wizard.

### Outputting database credentials

On the set up wizard, it is required to input database credentials to use a MySQL compatible database or Postgres. You can output its credentials by running the playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=print-db-credentials-farmos
```

### Configuring `trusted_host_patterns` setting (recommended)

After installation, you will find the error reported on the dashboard at `https://example.com/admin/reports/status` that the `trusted_host_patterns` setting is not configured in settings.php. You can fix the error by adding the configuration to the file at `/mash/farmos/data/sites/default/settings.php` manually.

Alternatively, you can automatically add the configuration to the file by running the command below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=trusted-host-farmos
```

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu farmos` (or how you/your playbook named the service, e.g. `mash-farmos`).
