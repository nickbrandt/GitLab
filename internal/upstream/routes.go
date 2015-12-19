package upstream

import (
	"../git"
	"../lfs"
	pr "../proxy"
	"../staticpages"
	"../upload"
	"net/http"
	"regexp"
)

type route struct {
	method  string
	regex   *regexp.Regexp
	handler http.Handler
}

const projectPattern = `^/[^/]+/[^/]+/`
const gitProjectPattern = `^/[^/]+/[^/]+\.git/`

const apiPattern = `^/api/`
const projectsAPIPattern = `^/api/v3/projects/[^/]+/`

const ciAPIPattern = `^/ci/api/`

// Routing table
// We match against URI not containing the relativeUrlRoot:
// see upstream.ServeHTTP

func (u *Upstream) Routes() []route {
	u.configureRoutesOnce.Do(u.configureRoutes)
	return u.routes
}

func (u *Upstream) configureRoutes() {
	static := &staticpages.Static{u.DocumentRoot}
	proxy := &pr.Proxy{URL: u.Backend, Version: u.Version, RoundTripper: u.RoundTripper()}
	u.routes = []route{
		// Git Clone
		route{"GET", regexp.MustCompile(gitProjectPattern + `info/refs\z`), git.GetInfoRefs(u.API())},
		route{"POST", regexp.MustCompile(gitProjectPattern + `git-upload-pack\z`), contentEncodingHandler(git.PostRPC(u.API()))},
		route{"POST", regexp.MustCompile(gitProjectPattern + `git-receive-pack\z`), contentEncodingHandler(git.PostRPC(u.API()))},
		route{"PUT", regexp.MustCompile(gitProjectPattern + `gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\z`), lfs.PutStore(u.API(), proxy)},

		// Repository Archive
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive\z`), git.GetArchive(u.API())},
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive.zip\z`), git.GetArchive(u.API())},
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive.tar\z`), git.GetArchive(u.API())},
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive.tar.gz\z`), git.GetArchive(u.API())},
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive.tar.bz2\z`), git.GetArchive(u.API())},

		// Repository Archive API
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive\z`), git.GetArchive(u.API())},
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive.zip\z`), git.GetArchive(u.API())},
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive.tar\z`), git.GetArchive(u.API())},
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive.tar.gz\z`), git.GetArchive(u.API())},
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive.tar.bz2\z`), git.GetArchive(u.API())},

		// CI Artifacts API
		route{"POST", regexp.MustCompile(ciAPIPattern + `v1/builds/[0-9]+/artifacts\z`), contentEncodingHandler(upload.Artifacts(u.API(), proxy))},

		// Explicitly proxy API requests
		route{"", regexp.MustCompile(apiPattern), proxy},
		route{"", regexp.MustCompile(ciAPIPattern), proxy},

		// Serve assets
		route{"", regexp.MustCompile(`^/assets/`),
			static.ServeExisting(u.URLPrefix(), staticpages.CacheExpireMax,
				NotFoundUnless(u.DevelopmentMode,
					proxy,
				),
			),
		},

		// Serve static files or forward the requests
		route{"", nil,
			static.ServeExisting(u.URLPrefix(), staticpages.CacheDisabled,
				static.DeployPage(
					static.ErrorPages(
						proxy,
					),
				),
			),
		},
	}
}
