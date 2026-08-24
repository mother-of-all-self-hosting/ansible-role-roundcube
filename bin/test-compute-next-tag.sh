#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Exercises bin/compute-next-tag.sh against throwaway git repositories.
#
# Usage: bin/test-compute-next-tag.sh
#
# Every scenario creates a repository in a temporary directory, gives it role
# files and a release history, and then replays a series of merges through the
# real script, tagging as it goes just like the autotag workflow does. This
# repository is never touched and no network access is needed.

set -euo pipefail

script_under_test="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/compute-next-tag.sh"

failures=0
workdir=''

cleanup() {
	cd /
	if [ -n "$workdir" ]; then
		rm -rf "$workdir"
		workdir=''
	fi
}

trap cleanup EXIT

# Writes a defaults/main.yml around the given Roundcube version, surrounded by
# the things that actually sit next to it in this role and that a sloppier
# version lookup would trip over: the Renovate annotation, a commented-out
# version, another variable whose name merely starts with `roundcube_version`,
# and `roundcube_container_image_self_build_repo_version`, which also ends in
# `_version` but holds a git branch rather than a release.
write_defaults() {
	cat > defaults/main.yml <<-EOF
		---
		roundcube_enabled: true

		# roundcube_version: 9.9.9
		roundcube_version_check_enabled: false

		# renovate: datasource=docker depName=roundcube/roundcubemail versioning=semver
		roundcube_version: $1

		roundcube_container_image_self_build_repo_version: master
	EOF
}

# Starts a scenario with a repository at Roundcube 1.6.14 which has already
# seen two releases of it (v1.6.14-0 and v1.6.14-1).
#
# Note that the version value carries no leading `v` while the tags do, which
# is how this role has always been released.
scenario() {
	echo "$1"

	cleanup
	workdir="$(mktemp -d)"

	mkdir -p "$workdir/bin" "$workdir/defaults" "$workdir/tasks" "$workdir/templates"
	cp "$script_under_test" "$workdir/bin/"
	cd "$workdir"

	git init -q -b main .
	git config user.email 'test@example.com'
	git config user.name 'Test'
	git config commit.gpgsign false

	write_defaults 1.6.14
	printf 'placeholder\n' > tasks/main.yml
	printf 'placeholder\n' > templates/env.j2
	printf 'placeholder\n' > README.md

	git add -A
	git commit -qm 'Initial commit'

	local release_number
	for release_number in 0 1; do
		git tag "v1.6.14-$release_number"
	done
}

# Applies a change, commits it, and tags whatever the script says it should be.
# Prints the tag, or nothing when the script decided against a release.
merge() {
	local change="$1" tag

	eval "$change"
	git add -A
	git commit -qm 'Merge'

	tag="$(bin/compute-next-tag.sh 2>/dev/null)"

	if [ -n "$tag" ]; then
		git tag "$tag"
	fi

	printf '%s' "$tag"
}

expect() {
	local description="$1" expected="$2" actual="$3"

	if [ "$actual" = "$expected" ]; then
		printf '  ok   | %s -> %s\n' "$description" "${actual:-no release}"
	else
		printf '  FAIL | %s -> expected %s, got %s\n' "$description" "${expected:-no release}" "${actual:-no release}"
		failures=$((failures + 1))
	fi
}

bump_version='write_defaults 1.6.15'
quote_version='write_defaults \"1.6.15\"'
revert_version='write_defaults 1.6.14'
bump_self_build_version="sed -i 's|self_build_repo_version: master|self_build_repo_version: 1.6.15|' defaults/main.yml"
edit_task="printf 'a task\n' >> tasks/main.yml"
edit_template="printf 'a line\n' >> templates/env.j2"
edit_readme="printf 'documentation\n' >> README.md"
edit_script="printf '# a comment\n' >> bin/compute-next-tag.sh"

# The two merge orders below apply the same updates and must each end up with
# every update released exactly once, whichever order they arrive in.

scenario 'A version bump merged before other role changes'
expect 'version bump' v1.6.15-0 "$(merge "$bump_version")"
expect 'task edit'    v1.6.15-1 "$(merge "$edit_task")"
expect 'template'     v1.6.15-2 "$(merge "$edit_template")"

scenario 'A version bump merged after other role changes'
expect 'task edit'    v1.6.14-2 "$(merge "$edit_task")"
expect 'version bump' v1.6.15-0 "$(merge "$bump_version")"

scenario 'Commits that do not affect the role'
expect 'README'   ''        "$(merge "$edit_readme")"
expect 'a script' ''        "$(merge "$edit_script")"
expect 'a task'   v1.6.14-2 "$(merge "$edit_task")"

scenario 'Release numbers past 9'
for release_number in 2 3 4 5 6 7 8 9 10; do
	git tag "v1.6.14-$release_number"
done
expect 'a task' v1.6.14-11 "$(merge "$edit_task")"

scenario 'Reverting to an already released version'
merge "$bump_version" > /dev/null
# The role is now identical to what v1.6.14-1 already published, so there is
# nothing new to release.
expect 'a revert' ''        "$(merge "$revert_version")"

scenario 'Reverting to an already released version, with a change'
merge "$bump_version" > /dev/null
expect 'a revert' v1.6.14-2 "$(merge "$revert_version && $edit_task")"

# The version may be written with or without quotes, and both must name the
# same release rather than one whose name has quotes baked into it. Unquoting
# is still an edit under defaults/, so it does earn a release of its own - the
# point being that it is another release of 1.6.15 and not a first release of
# something spelled `"1.6.15"`.
scenario 'A quoted version value'
expect 'quoted bump'   v1.6.15-0 "$(merge "$quote_version")"
expect 'then unquoted' v1.6.15-1 "$(merge "$bump_version")"

# `roundcube_container_image_self_build_repo_version` also ends in `_version`,
# so a lookup that is not anchored on the exact variable name would read the
# release out of it and tag a self-build branch change as a Roundcube release.
scenario 'A self-build repo version that is not the Roundcube version'
expect 'self-build bump' v1.6.14-2 "$(merge "$bump_self_build_version")"

if [ "$failures" -gt 0 ]; then
	echo >&2 "$failures scenario(s) behaved unexpectedly"
	exit 1
fi

echo 'All scenarios behaved as expected'
