import git


def git_changes(repo_path, from_branch, to_branch='origin/master'):
    repo = git.Repo(repo_path)
    from_branch_commit = repo.commit(from_branch)
    to_branch_commit = repo.commit(to_branch)
    diff_index = to_branch_commit.diff(from_branch_commit)

    return list(set(
        [x.a_blob.path for x in diff_index.iter_change_type('A') if x.a_blob] +
        [x.a_blob.path for x in diff_index.iter_change_type('R') if x.a_blob] +
        [x.a_blob.path for x in diff_index.iter_change_type('M') if x.a_blob] +
        [x.a_blob.path for x in diff_index.iter_change_type('T') if x.a_blob]
    ))
