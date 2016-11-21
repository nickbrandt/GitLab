package terminal

import (
	"log"
	"net"
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/websocket"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

var (
	// See doc/terminal.md for documentation of this subprotocol
	subprotocols             = []string{"terminal.gitlab.com", "base64.terminal.gitlab.com"}
	upgrader                 = &websocket.Upgrader{Subprotocols: subprotocols}
	ReauthenticationInterval = 5 * time.Minute
	BrowserPingInterval      = 30 * time.Second
)

func Handler(myAPI *api.API) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		if err := a.Terminal.Validate(); err != nil {
			helper.Fail500(w, r, err)
			return
		}

		proxy := NewProxy(1) // one stopper: auth checker
		checker := NewAuthChecker(
			authCheckFunc(myAPI, r, "authorize"),
			a.Terminal,
			proxy.StopCh,
		)
		defer checker.Close()
		go checker.Loop(ReauthenticationInterval)

		ProxyTerminal(w, r, a.Terminal, proxy)
	}, "authorize")
}

func ProxyTerminal(w http.ResponseWriter, r *http.Request, terminal *api.TerminalSettings, proxy *Proxy) {
	server, err := connectToServer(terminal, r)
	if err != nil {
		helper.Fail500(w, r, err)
		log.Printf("Terminal: connecting to server failed: %s", err)
		return
	}
	defer server.UnderlyingConn().Close()
	serverAddr := server.UnderlyingConn().RemoteAddr().String()

	client, err := upgradeClient(w, r)
	if err != nil {
		log.Printf("Terminal: upgrading client to websocket failed: %s", err)
		return
	}

	// Regularly send ping messages to the browser to keep the websocket from
	// being timed out by intervening proxies.
	go pingLoop(client)

	defer client.UnderlyingConn().Close()
	clientAddr := getClientAddr(r) // We can't know the port with confidence

	log.Printf("Terminal: started proxying from %s to %s", clientAddr, serverAddr)
	defer log.Printf("Terminal: finished proxying from %s to %s", clientAddr, serverAddr)

	if err := proxy.Serve(server, client, serverAddr, clientAddr); err != nil {
		log.Printf("Terminal: error proxying from %s to %s: %s", clientAddr, serverAddr, err)
	}
}

// In the future, we might want to look at X-Client-Ip or X-Forwarded-For
func getClientAddr(r *http.Request) string {
	return r.RemoteAddr
}

func upgradeClient(w http.ResponseWriter, r *http.Request) (Connection, error) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return nil, err
	}

	return Wrap(conn, conn.Subprotocol()), nil
}

func pingLoop(conn Connection) {
	for {
		time.Sleep(BrowserPingInterval)
		deadline := time.Now().Add(5 * time.Second)
		if err := conn.WriteControl(websocket.PingMessage, nil, deadline); err != nil {
			// Either the connection was already closed so no further pings are
			// needed, or this connection is now dead and no further pings can
			// be sent.
			break
		}
	}
}

func connectToServer(terminal *api.TerminalSettings, r *http.Request) (Connection, error) {
	terminal = terminal.Clone()

	// Pass along X-Forwarded-For, appending request.RemoteAddr, to the server
	// we're connecting to.
	if ip, _, err := net.SplitHostPort(r.RemoteAddr); err == nil {
		if chains, ok := r.Header["X-Forwarded-For"]; ok {
			terminal.Header.Set("X-Forwarded-For", strings.Join(chains, ", ")+", "+ip)
		} else {
			terminal.Header.Set("X-Forwarded-For", ip)
		}
	}

	conn, _, err := terminal.Dial()
	if err != nil {
		return nil, err
	}

	return Wrap(conn, conn.Subprotocol()), nil
}
