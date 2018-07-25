#!/bin/bash
#
# add-gitlab-merge-requests.sh [origin] [remote]
#
# For modules hosted in gitlab, this adds a new remote named [remote] (default
# 'merge-requests') that points to the same URL as [origin] (default 'origin'),
# whose heads are the merge requests for that module. Such names are then
# visible in 'git log' decorations, eg:
#
#     commit 4bfb35c1ddebc6074608c129cdce702772d47bb6 (merge-requests/51)
#     Author: Peter Hutterer <peter.hutterer@who-t.net>
#     Date:   Mon Jul 23 21:21:31 2018 +1000
#
#     Gitlab CI: properly define empty dependencies for the wayland-web hook
#
# And in general they behave exactly like any other branch or remote,
# including that they are fetched independently from [origin].

origin=${1:-origin}
url=$(git remote get-url ${origin})
remote=${2:-merge-requests}

git remote add ${remote} ${url}
git config remote.${remote}.fetch \
    "+refs/merge-requests/*/head:refs/remotes/${remote}/*"
git fetch ${remote}
