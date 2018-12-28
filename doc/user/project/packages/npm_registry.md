# GitLab NPM Registry **[PREMIUM]**

> Introduced in [GitLab Premium](https://about.gitlab.com/pricing/) 11.7.

With the GitLab NPM Registry, every
project can have its own space to store NPM packages.

![GitLab NPM Registry](img/npm_package_view.png)

NOTE: **Note:**
Only [scoped](https://docs.npmjs.com/misc/scope) packages are supported. 

## Enabling NPM Registry

NOTE: **Note:**
This option is available only if your GitLab administrator has
[enabled Packages feature](../../../administration/npm_registry.md).

In order to use the GitLab NPM Registry, you must enable the Packages feature.
To enable (or disable) it:

1. Navigate to your project's **Settings > General > Permissions**.
1. Find the "Packages" feature and enable it.
1. Click on **Save changes** for the changes to take effect.

You should then be able to see the **Packages** section on the left sidebar.
Next, you must configure your project to authorize with the GitLab NPM
registry.

## Package naming convention

Note that **only packages that have the same path as the project** are supported.

| Project | Package | Supported |
| ------- | ------- | --------------------------------- |
| `foo/bar`              | `@foo/bar`              | Yes |
| `gitlab-org/gitlab-ce` | `@foo/bar`              | No  |
| `gitlab-org/gitlab-ce` | `@gitlab-org/gitlab-ce` | Yes |

## Authenticating to the GitLab NPM Registry

If a project is private or you want to upload NPM package to GitLab,
credentials will need to be provided for authentication. Support is available for
[oauth tokens](#authenticating-with-an-oauth-token) only.

### Authenticating with an oauth token

To authenticate with a [oauth token](../../../api/oauth2.md),
add a corresponding section to your `.npmrc` file:

```
; Set URL for your scoped packages. 
; For example package with name `@foo/bar` will use this URL for download 
@foo:registry=https://gitlab.com/api/v4/packages/npm/

; Add OAuth token for scoped packages URL. This will allow you to download
; `@foo/` packages from private projects.  
//localhost:3001/api/v4/packages/npm/:_authToken=1da4f6691c92a543f7416b8fe013357fda23b0730466841311b89809a51349ce

; Add OAuth token for uploading to the registry. Replace `YOUR_PROJECT_ID`
; with a project you want your package uploaded to. 
//gitlab.com/api/v4/projects/YOUR_PROJECT_ID/packages/npm/:_authToken=YOUR_OAUTH_TOKEN
```

You should now be able to download and upload NPM packages to your project.

## Uploading packages

Before you will be able to upload a package, you need to specify registry for NPM. 
To do this, you need to add next section to the bottom of `package.json`: 

```json
  "publishConfig": {
    "@foo:registry":"https://gitlab.com/api/v4/projects/YOUR_PROJECT_ID/packages/npm/"
  }
```
Replace `YOUR_PROJECT_ID` with a project you want your package uploaded to. 
And replace `@foo` with your own scope.

Once you did it and have set up the [authorization](#authorizing-with-the-gitlab-npm-registry),
test to upload an NPM package from a project of yours:

```sh
npm publish
```

You can then navigate to your project's **Packages** page and see the uploaded
packages or even delete them.

## Uploading a package with the same version twice

If you upload a package with a same name and version twice, GitLab will show 
both packages in UI. But API will expose only one package per version for `npm install`
and it will be the most recent one.
