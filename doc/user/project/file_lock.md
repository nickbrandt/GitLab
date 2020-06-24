# File Locking

When working with binary files in a collaborative project, file locking helps
prevent multiple people changing the same file at the same time. Branching works
for source code and plain text because different versions can be merged
together, but this does not work for binary files.

When a file is locked, only the user who locked the file may modify it. This
user is said to "hold the lock" or have "taken the lock", since only one user
may lock a file at a time. When a file or directory is unlocked, the user is
said to have "released the lock".

GitLab supports two different modes of file locking:

- [Exclusive locks](#exclusive-file-locks) for binary files, to
  prevent locked files being modified on any branch.
- [Default branch locks](#default-branch-file-and-directory-locks) to prevent
  locked files and directories being modified on the default branch.

## Permissions

Only the user who locked the file or directory can edit locked files. Others
users will be prevented from modifying locked files through by pushing, merging
or any other means, and will be shown an error like: `The path '.gitignore' is
locked by Administrator`

Locks can be created by any person who has [push access](../permissions.md) to
the repository, Developer permissions and above.

Locks can be only be removed by their author, or any user with Maintainer
permissions and above.

## Exclusive file locks **(CORE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/35856) in GitLab 10.5.

Preventing wasted work caused by unresolvable merge conflicts prevents requires
a different way of working. This means explicitly requesting write permissions,
and verifying no one else is editing the same file before editing begins.

When file locking is setup, lockable files are **read only** by default.

1. To edit a file, request the lock. This verifies that no one else is editing
   the file, and prevents anyone else editing the file until you're done.

   ```shell
   git lfs lock path/to/file.png
   ```

1. When you're done, return the lock. This communicates that you finished
   editing the file, and allows other people to edit the file.

   ```shell
   git lfs unlock path/to/file.png
   ```

TODO: workflow suggestion - don't unlock until the change is in the default
branch. Maybe this can be a follow up on practical workflows.

NOTE: **Note:**
Although multi-branch file locks can be created and managed through the Git LFS
command line interface, file locks can be created for any file.

### Getting started (user)

TODO: how do I use file locks on an existing project that someone has already
setup. E.g. what do I do after running `git clone`

1. Install Git LFS

   ```shell
   git lfs install
   ```

1. Fetch the current file lock status, and update file permissions so that
   lockable files are read only.

   ```shell
   git lfs locks
   git checkout .
   ```

### Configure lockable files (maintainer)

The first thing to do before using File Locking is to tell Git LFS which
kind of files are lockable. The following command will store PNG files
in LFS and flag them as lockable:

```shell
git lfs track "*.png" --lockable
```

After executing the above command a file named `.gitattributes` will be
created or updated with the following content:

```shell
*.png filter=lfs diff=lfs merge=lfs -text lockable
```

You can also register a file type as lockable without using LFS
(In order to be able to lock/unlock a file you need a remote server that implements the LFS File Locking API),
in order to do that you can edit the `.gitattributes` file manually:

```shell
*.pdf lockable
```

After a file type has been registered as lockable, Git LFS will make
them read-only on the file system automatically. This means you will
need to lock the file before editing it.

TODO: reminder that `.gitattributes` should be commited to the repo!

### Managing locked files

Once you're ready to edit your file you need to lock it first:

```shell
git lfs lock images/banner.png
Locked images/banner.png
```

This will register the file as locked in your name on the server:

```shell
git lfs locks
images/banner.png  joe   ID:123
```

Once you have pushed your changes, you can unlock the file so others can
also edit it:

```shell
git lfs unlock images/banner.png
```

You can also unlock by ID:

```shell
git lfs unlock --id=123
```

If for some reason you need to unlock a file that was not locked by you,
you can use the `--force` flag as long as you have a `maintainer` access on
the project:

```shell
git lfs unlock --id=123 --force
```

## Default branch file and directory locks **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/440) in [GitLab Premium](https://about.gitlab.com/pricing/) 8.9.

Default branch file and directory locks only apply to the default branch set in
the project's settings (usually `master`).

Changes to locked files on the default branch will be blocked, including merge
requests that modify locked files. Unlock the file to allow changes.

### Locking and unlocking a file or a directory

To lock a file:

1. Open the file or directory in GitLab.
1. Click the **Lock** button, located near the Web IDE button.

   ![Locking file](img/file_lock.png)

An **Unlock** button will be displayed if the file is already locked, and
will be disabled if you do not have permission to unlock the file.

If you did not lock the file, hovering your cursor over the button will show who
locked the file.

### Viewing and remove existing locks

The **Locked Files**, accessed from **Project > Repository** left menu, lists
all file and directory locks. Locks can be removed by their author, or any user
with Maintainer permissions and above.

