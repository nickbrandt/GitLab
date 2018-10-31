# Packages Migrate Rake Task

## Migrate to Object Storage

After [configuring the object storage](../../maven_repository.md#using-object-storage) for GitLab's packages, you may use this task to migrate existing packages from the local storage to the remote storage.

>**Note:**
All of the processing will be done in a background worker and requires **no downtime**.

### All-in-one rake task

GitLab provides a rake task that migrates all uploaded packages to object storage.

**Omnibus Installation**

```bash
gitlab-rake "gitlab:packages:migrate"
```

**Source Installation**

```bash
sudo RAILS_ENV=production -u git -H bundle exec rake gitlab:packages:migrate
```
