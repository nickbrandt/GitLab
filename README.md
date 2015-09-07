# gitlab-git-http-server

gitlab-git-http-server was designed to unload Git HTTP traffic from
the GitLab Rails app (Unicorn) to a separate daemon. All authentication
and authorization logic is still handled by the GitLab Rails app.

Architecture: Git client -> NGINX -> gitlab-git-http-server (makes
auth request to GitLab Rails app) -> git-upload-pack

## Usage

```
  gitlab-git-http-server [OPTIONS] REPO_ROOT

Options:
  -authBackend string
    	Authentication/authorization backend (default "http://localhost:8080")
  -listenAddr string
    	Listen address for HTTP server (default "localhost:8181")
  -listenNetwork string
    	Listen 'network' (tcp, tcp4, tcp6, unix) (default "tcp")
  -listenUmask int
    	Umask for Unix socket, default: 022 (default 18)
  -pprofListenAddr string
    	pprof listening address, e.g. 'localhost:6060'
  -version
    	Print version and exit
```

gitlab-git-http-server allows Git HTTP clients to push and pull to and from Git
repositories under REPO_ROOT. Each incoming request is first replayed (with an
empty request body) to an external authentication/authorization HTTP server:
the 'auth backend'. The auth backend is expected to be a GitLab Unicorn
process.

gitlab-git-http-server can listen on either a TCP or a Unix domain socket. It
can also open a second listening TCP listening socket with the Go
[net/http/pprof profiler server](http://golang.org/pkg/net/http/pprof/).

## Installation

To install into `/usr/local/bin` run `make install`.

```
make install
```

To install into `/foo/bin` set the PREFIX variable.

```
make install PREFIX=/foo
```

## Tests

```
make clean test
```

## Try it out

You can try out the Git server without authentication as follows:

```
# Start a fake auth backend that allows everything/everybody
go run support/say-yes.go &
# Start gitlab-git-http-server
go build && ./gitlab-git-http-server /path/to/git-repos
```

Now if you have a Git repository in `/path/to/git-repos/my-repo.git`,
you can push to and pull from it at the URL
`http://localhost:8181/my-repo.git`.

## Example request flow

- start POST repo.git/git-receive-pack to NGINX
- ..start POST repo.git/git-receive-pack to gitlab-git-http-server
- ....start POST repo.git/git-receive-pack to Unicorn for auth
- ....end POST to Unicorn for auth
- ....start git-receive-pack process from gitlab-git-http-server
- ......start POST /api/v3/internal/allowed to Unicorn from Git hook (check protected branches)
- ......end POST to Unicorn from Git hook
- ....end git-receive-pack process
- ..end POST to gitlab-git-http-server
- end POST to NGINX

## License

This code is distributed under the MIT license, see the LICENSE file.
