# SPDX-FileCopyrightText: 2023 Sergio Durigan Junior
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# show help by default
default:
    @{{ just_executable() }} --list --justfile {{ justfile() }}

lint:
    ansible-lint .
