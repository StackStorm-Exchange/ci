#### gh helpers

_gh_default_branch() {
    # get the default branch for the current repo (might not be master)

    gh api graphql -F owner=':owner' -F name=':repo' -f query='
      query($name: String!, $owner: String!) {
        repository(owner: $owner, name: $name) {
          defaultBranchRef { name }
        }
      }
    ' | jq -r '.data.repository.defaultBranchRef.name'
}
