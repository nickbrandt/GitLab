# gitlab-git-http-server

This is a proof of concept for unloading Git HTTP traffic from the
GitLab Rails app (Unicorn) to a separate daemon. All authentication
and authorization logic is still handled by the GitLab Rails app.

Architecture: Git client -> NGINX -> gitlab-git-http-server (makes
auth request to GitLab Rails app) -> git-upload-pack

There are two patches in the repo that show what would need to
change in GitLab / NGINX to make this work.
