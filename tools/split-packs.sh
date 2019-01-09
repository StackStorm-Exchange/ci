#!/bin/bash

##
#  This migration script is provided without warranty.
#  Use at your own risk, and backup your repo before running.
#
#  Note: This script does not create your remote repo.
#  It is assumed you have already created an empty repo
#  on the remote host with the pack name "stackstorm-<pack>".
##

set -e

if [ $# -lt 1 ] || [[ $1 =~ ^-+h(elp)?$ ]] ; then
    echo "Usage: $0 subtree_repo_url [new_org_url]"
    echo "Example: $0 https://github.com/example/mysubtreerepo.git git@github.com:example2"
    exit
fi
SUBTREE_REPO_URL=$1
if [ $# -gt 1 ] ; then
    EXCHANGE_ORG_URL=$2
else
    EXCHANGE_ORG_URL=$(dirname $1)
fi
if [[ $EXCHANGE_ORG_URL =~ ^http ]]; then
    EXCHANGE_ORG=$(basename $EXCHANGE_ORG_URL)
elif [[ $EXCHANGE_ORG_URL =~ ^git ]]; then
    EXCHANGE_ORG=$(echo $EXCHANGE_ORG_URL | rev | cut -d: -f1 | rev)
else
    echo "Invalid git URL: $EXCHANGE_ORG_URL"
    exit 1
fi 
SUBTREE_ORG=$(basename $(dirname $1))
SUBTREE_REPO=$(basename $1 | cut -d. -f1 )
EXCHANGE_PREFIX=stackstorm

echo 
echo "Splitting pack from $SUBTREE_ORG/$SUBTREE_REPO to $EXCHANGE_ORG/$EXCHANGE_PREFIX-pack1, $EXCHANGE_ORG/$EXCHANGE_PREFIX-pack2, etc."
echo "==========================================================================="
echo

rm -rf /tmp/$SUBTREE_REPO
rm -rf /tmp/$EXCHANGE_ORG
mkdir /tmp/$SUBTREE_REPO /tmp/$EXCHANGE_ORG

git clone $SUBTREE_REPO_URL /tmp/$SUBTREE_REPO
cd /tmp/$SUBTREE_REPO/packs

echo
git remote remove origin
for PACK in `ls`; do
  echo -n "Moving $PACK... "
  if ! git ls-remote $EXCHANGE_ORG_URL/$EXCHANGE_PREFIX-$PACK > /dev/null 2>&1
  then
  	echo "Remote repo $EXCHANGE_ORG_URL/$EXCHANGE_PREFIX-$PACK not found."
  	echo
  	continue
  fi
  echo
  
  mkdir /tmp/$EXCHANGE_ORG/$PACK
  cd /tmp/$EXCHANGE_ORG/$PACK
  cp -R /tmp/$SUBTREE_REPO/. .

  git filter-branch --prune-empty --subdirectory-filter packs/$PACK -f -- master
  git remote add origin $EXCHANGE_ORG_URL/$EXCHANGE_PREFIX-$PACK.git
  git fetch --all -q

  if git log -n3 --oneline | grep -q "Transfer from $SUBTREE_ORG/$SUBTREE_REPO."
  then
  	echo "Already transferred to $EXCHANGE_ORG_URL/$EXCHANGE_PREFIX-$PACK."
    echo
  	continue
  fi
  echo

  chmod -R 775 .
  git commit -q -am "Transfer from $SUBTREE_ORG/$SUBTREE_REPO." > /dev/null

  git push -u origin master --force > /dev/null

  echo "The $PACK pack has been transferred."
  echo
done
echo

rm -rf /tmp/$SUBTREE_REPO
rm -rf /tmp/$EXCHANGE_ORG
echo "All done."