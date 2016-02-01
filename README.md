# gitlab-workhorse

Gitlab-workhorse is a smart reverse proxy for GitLab. It handles
"large" HTTP requests such as file downloads, file uploads, Git
push/pull and Git archive downloads.


## Usage

```
  gitlab-workhorse [OPTIONS]

Options:
  -authBackend string
    	Authentication/authorization backend (default "http://localhost:8080")
  -authSocket string
    	Optional: Unix domain socket to dial authBackend at
  -developmentMode
    	Allow to serve assets from Rails app
  -documentRoot string
    	Path to static files content (default "public")
  -listenAddr string
    	Listen address for HTTP server (default "localhost:8181")
  -listenNetwork string
    	Listen 'network' (tcp, tcp4, tcp6, unix) (default "tcp")
  -listenUmask int
    	Umask for Unix socket, default: 022 (default 18)
  -pprofListenAddr string
    	pprof listening address, e.g. 'localhost:6060'
  -proxyHeadersTimeout duration
    	How long to wait for response headers when proxying the request (default 1m0s)
  -version
    	Print version and exit
```

The 'auth backend' refers to the GitLab Rails application. The name is
a holdover from when gitlab-workhorse only handled Git push/pull over
HTTP.

Gitlab-workhorse can listen on either a TCP or a Unix domain socket. It
can also open a second listening TCP listening socket with the Go
[net/http/pprof profiler server](http://golang.org/pkg/net/http/pprof/).

### Relative URL support

If you are mounting GitLab at a relative URL, e.g.
`example.com/gitlab`, then you should also use this relative URL in
the `authBackend` setting:

```
gitlab-workhorse -authBackend http://localhost:8080/gitlab
```

## Installation

To install gitlab-workhorse you need [Go 1.5 or
newer](https://golang.org/dl).

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
make test/data/test.git
go run support/fake-auth-backend.go ~+/test/data/test.git &
# Start gitlab-workhorse
make
./gitlab-workhorse
```

Now you can try things like:

```
git clone http://localhost:8181/test.git
curl -JO http://localhost:8181/test/repository/archive.zip
```

## Example request flow

- start POST repo.git/git-receive-pack to NGINX
- ..start POST repo.git/git-receive-pack to gitlab-workhorse
- ....start POST repo.git/git-receive-pack to Unicorn for auth
- ....end POST to Unicorn for auth
- ....start git-receive-pack process from gitlab-workhorse
- ......start POST /api/v3/internal/allowed to Unicorn from Git hook (check protected branches)
- ......end POST to Unicorn from Git hook
- ....end git-receive-pack process
- ..end POST to gitlab-workhorse
- end POST to NGINX

## License

This code is distributed under the MIT license, see the LICENSE file.
