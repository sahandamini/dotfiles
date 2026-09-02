# Temporary Workspaces

Use Worktrunk for temporary Git worktrees. Run `wt switch --create <branch>` to
create a worktree. In non-interactive shells, read the returned path and use it
as the tool `workdir`. Do not assume that `wt` changes the parent process path.
Run `wt remove <branch>` to remove the worktree.
