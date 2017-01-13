package redis

import (
	"errors"
	"fmt"
	"log"
	"strings"
	"sync"
	"time"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"

	"github.com/garyburd/redigo/redis"
	"github.com/jpillora/backoff"
	"github.com/prometheus/client_golang/prometheus"
)

var (
	keyWatcher            = make(map[string][]chan string)
	keyWatcherMutex       sync.Mutex
	redisReconnectTimeout = backoff.Backoff{
		//These are the defaults
		Min:    100 * time.Millisecond,
		Max:    60 * time.Second,
		Factor: 2,
		Jitter: true,
	}
	keyWatchers = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_keywatcher_keywatchers",
			Help: "The number of keys that is being watched by gitlab-workhorse",
		},
	)
	totalMessages = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywather_total_messages",
			Help: "How many messages gitlab-workhorse has recieved in total on pubsub.",
		},
	)
)

func init() {
	prometheus.MustRegister(
		keyWatchers,
		totalMessages,
	)
}

const (
	keySubChannel  = "workhorse:notifications"
	promStatusMiss = "miss"
	promStatusHit  = "hit"
)

// KeyChan holds a key and a channel
type KeyChan struct {
	Key  string
	Chan chan string
}

func processInner(conn redis.Conn) {
	redisReconnectTimeout.Reset()

	defer conn.Close()
	psc := redis.PubSubConn{Conn: conn}
	if err := psc.Subscribe(keySubChannel); err != nil {
		return
	}
	defer psc.Unsubscribe(keySubChannel)

	for {
		switch v := psc.Receive().(type) {
		case redis.Message:
			totalMessages.Inc()
			msg := strings.SplitN(string(v.Data), "=", 2)
			if len(msg) != 2 {
				helper.LogError(nil, errors.New("Redis subscribe error: got an invalid notification"))
				continue
			}
			key, value := msg[0], msg[1]
			notifyChanWatchers(key, value)
		case error:
			helper.LogError(nil, fmt.Errorf("Redis subscribe error: %s", v))
			return
		}
	}
}

// Process redis subscriptions
//
// NOTE: There Can Only Be One!
// Reconnects is reconnect = true
func Process(reconnect bool) {
	log.Print("Processing redis queue")

	loop := true
	for loop {
		loop = reconnect
		log.Println("Connecting to redis")
		conn, err := redisDialFunc()
		if err != nil {
			helper.LogError(nil, fmt.Errorf("Failed to connect to redis: %s", err))
			time.Sleep(redisReconnectTimeout.Duration())
			continue
		}
		processInner(conn)
	}
}

func notifyChanWatchers(key, value string) {
	keyWatcherMutex.Lock()
	defer keyWatcherMutex.Unlock()
	if chanList, ok := keyWatcher[key]; ok {
		for _, c := range chanList {
			c <- value
			keyWatchers.Dec()
		}
		delete(keyWatcher, key)
	}
}

func addKeyChan(kc *KeyChan) {
	keyWatcherMutex.Lock()
	defer keyWatcherMutex.Unlock()
	keyWatcher[kc.Key] = append(keyWatcher[kc.Key], kc.Chan)
	keyWatchers.Inc()
}

func delKeyChan(kc *KeyChan) {
	keyWatcherMutex.Lock()
	defer keyWatcherMutex.Unlock()
	if chans, ok := keyWatcher[kc.Key]; ok {
		for i, c := range chans {
			if kc.Chan == c {
				keyWatcher[kc.Key] = append(chans[:i], chans[i+1:]...)
				keyWatchers.Dec()
				break
			}
		}
		if len(keyWatcher[kc.Key]) == 0 {
			delete(keyWatcher, kc.Key)
		}
	}
}

// WatchKeyStatus is used to tell how WatchKey returned
type WatchKeyStatus int

const (
	// WatchKeyStatusTimeout is returned when the watch timeout provided by the caller was exceeded
	WatchKeyStatusTimeout WatchKeyStatus = iota
	// WatchKeyStatusAlreadyChanged is returned when the value passed by the caller was never observed
	WatchKeyStatusAlreadyChanged
	// WatchKeyStatusSeenChange is returned when we have seen the value passed by the caller get changed
	WatchKeyStatusSeenChange
	// WatchKeyStatusNoChange is returned when the function had to return before observing a change.
	//  Also returned on errors.
	WatchKeyStatusNoChange
)

// WatchKey waits for a key to be updated or expired
func WatchKey(key, value string, timeout time.Duration) (WatchKeyStatus, error) {
	kw := &KeyChan{
		Key:  key,
		Chan: make(chan string, 1),
	}

	addKeyChan(kw)
	defer delKeyChan(kw)

	currentValue, err := GetString(key)
	if err != nil {
		return WatchKeyStatusNoChange, fmt.Errorf("Failed to get value from Redis: %#v", err)
	}
	if currentValue != value {
		return WatchKeyStatusAlreadyChanged, nil
	}

	select {
	case currentValue := <-kw.Chan:
		if currentValue == "" {
			return WatchKeyStatusNoChange, fmt.Errorf("Failed to get value from Redis")
		}
		if currentValue == value {
			return WatchKeyStatusNoChange, nil
		}
		return WatchKeyStatusSeenChange, nil

	case <-time.After(timeout):
		return WatchKeyStatusTimeout, nil
	}
}
