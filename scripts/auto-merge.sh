#!/usr/bin/env bash

set -eu

current_branch=$CIRCLE_BRANCH
repo_url=$CIRCLE_REPOSITORY_URL

if [[ ${current_branch} =~ ^ch([1-9]+)(\.([0-9]+))?(\.([0-9]+))?(\.([0-9]+))?$ ]]; then
    chapter=${BASH_REMATCH[1]}
    section=${BASH_REMATCH[3]}
    paragraph=${BASH_REMATCH[5]}
    number=${BASH_REMATCH[7]}

    echo chapter: $chapter
    echo section: $section
    echo paragraph: $paragraph
    echo number: $number
else
    echo "not target branch"
    exit 0
fi

if [[ ${repo_url} =~ ^git@github\.com:(.+)/(.+)\.git$ ]]; then
    GITHUB_ORG=${BASH_REMATCH[1]}
    GITHUB_REPO=${BASH_REMATCH[2]}
    echo GITHUB_ORG: ${GITHUB_ORG}
    echo GITHUB_REPO: ${GITHUB_REPO}
else
    exit 1
fi


found=""
next_branch=""
remote_branches=$(git branch --list -r | grep -v HEAD | grep -E 'origin/ch[0-9]+(\.[0-9]+)?(\.[0-9]+)?(\.[0-9]+)?' | sort)
for remote_branch in $remote_branches
do
    if [[ -n "${found}" ]]; then
        next_branch=${remote_branch#origin/}
        break
    fi
    if [[ "origin/${current_branch}" == "${remote_branch}" ]]; then
        found=true
    fi
done

if [[ -z "${next_branch}" ]]; then
    echo "not found next chapter branch."
    exit 0
fi

echo "merge to ${next_branch}"
# TODO: Change email and name
git config --global user.email "example@example.com"
git config --global user.name "circle ci"

git checkout ${next_branch}
git rebase $current_branch

git push https://${GITHUB_TOKEN}:x-oauth-basic@github.com/${GITHUB_ORG}/${GITHUB_REPO} ${next_branch} -f
