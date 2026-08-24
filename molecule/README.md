<!--
SPDX-FileCopyrightText: 2018-2025 Slavi Pantaleev
SPDX-FileCopyrightText: 2019-2022 Aaron Raimist
SPDX-FileCopyrightText: 2019-2023 MDAD project contributors
SPDX-FileCopyrightText: 2023 QEDeD
SPDX-FileCopyrightText: 2024 Fabio Bonelli
SPDX-FileCopyrightText: 2024 Nikita Chernyi
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara
SPDX-FileCopyrightText: 2026 spatterlight

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Molecule Testing

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

## Prerequisites

To utilize Molecule you need to prepare several requirements:

- **x86** computer running one of these operating systems that make use of [systemd](https://systemd.io/):
  - **Archlinux**
  - **CentOS**, **Rocky Linux**, **AlmaLinux**, or possibly other RHEL alternatives (although your mileage may vary)
  - **Debian** (10/Buster or newer)
  - **Ubuntu** (18.04 or newer, although [20.04 may be problematic](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/ansible.md#supported-ansible-versions) if you run the Ansible playbook on it)
- `root` access on the computer which Molecule runs against
- [Ansible](http://ansible.com/) program
- [Python](https://www.python.org/)
  - Most distributions install Python by default, but some don't (e.g. Ubuntu 18.04) and require manual installation (something like `apt-get install python3`)
- [Docker](https://www.docker.com)
  - Access to Docker UNIX socket (`/var/run/docker.sock`) is required by default

## Installation

To set up the environment for using Molecule, run the command below on the terminal:

```bash
python3 -m venv ./molecule/venv
source ./molecule/venv/bin/activate
pip3 install -r ./molecule/requirements.txt
```

## What the scenarios check

Roundcube is a mail client, so a running Roundcube on its own proves very little — the upstream container image with no configuration at all still serves a login page. Every scenario therefore starts a throwaway [GreenMail](https://greenmail-mail-test.github.io/greenmail/) mail server on the role's own container network and climbs the same ladder:

1. the login page renders, rather than a PHP or database error page
2. the version the running Roundcube reports matches the image tag the role deployed
3. the IMAP and SMTP servers the role configured are in the configuration that the Roundcube process loads
4. a login as a real mailbox user completes, and the mail server logs the IMAP authentication
5. the identity that the first login wrote to the database is served back through the settings page

Rungs 4 and 5 are the ones that cannot pass by accident: they need the role's configuration to reach the PHP process, the container network to carry the IMAP connection, and the scenario's database to accept a write and return it.

## Scenarios

Currently these testing scenarios are available:

### `default`

Tests a standard Roundcube installation.

### `default-selfbuild`

Tests a standard Roundcube installation with self-building the container image.

### `mariadb`

Tests a standard Roundcube installation with the MariaDB database.

### `postgres`

Tests a standard Roundcube installation with the Postgres database.

## Running

By default it is configured to run the scenarios on Ubuntu 26.04.

```bash
molecule test --scenario-name default
```

You can utilize other distributions by setting one to the `MOLECULE_DISTRO` environment variable:

```bash
# Ubuntu 24.04
MOLECULE_DISTRO=ubuntu2404 molecule test --scenario-name default

# Debian 13
MOLECULE_DISTRO=debian13 molecule test --scenario-name default

# Debian 12
MOLECULE_DISTRO=debian12 molecule test --scenario-name default
```
