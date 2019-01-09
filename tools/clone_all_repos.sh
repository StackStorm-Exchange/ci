#!/usr/bin/env bash

# Script which clones all the pack repos

curl -s "https://api.github.com/users/StackStorm-Exchange/repos?per_page=100&page=1" | python -c $'import json, sys, os\nfor repo in json.load(sys.stdin):\n  if not  repo["name"].startswith("stackstorm"):\n    continue\n  os.system("git clone " + repo["ssh_url"])'
curl -s "https://api.github.com/users/StackStorm-Exchange/repos?per_page=100&page=2" | python -c $'import json, sys, os\nfor repo in json.load(sys.stdin):\n  if not  repo["name"].startswith("stackstorm"):\n    continue\n  os.system("git clone " + repo["ssh_url"])'
curl -s "https://api.github.com/users/StackStorm-Exchange/repos?per_page=100&page=3" | python -c $'import json, sys, os\nfor repo in json.load(sys.stdin):\n  if not  repo["name"].startswith("stackstorm"):\n    continue\n  os.system("git clone " + repo["ssh_url"])'
