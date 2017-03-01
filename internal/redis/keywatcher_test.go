package redis

import (
	"sync"
	"testing"
	"time"

	"github.com/rafaeljusto/redigomock"
	"github.com/stretchr/testify/assert"
)

const (
	runnerKey = "runner:build_queue:10"
)

func createSubscriptionMessage(key, data string) []interface{} {
	return []interface{}{
		[]byte("message"),
		[]byte(key),
		[]byte(data),
	}
}

func createSubscribeMessage(key string) []interface{} {
	return []interface{}{
		[]byte("subscribe"),
		[]byte(key),
		[]byte("1"),
	}
}
func createUnsubscribeMessage(key string) []interface{} {
	return []interface{}{
		[]byte("unsubscribe"),
		[]byte(key),
		[]byte("1"),
	}
}

func TestWatchKeySeenChange(t *testing.T) {
	mconn, td := setupMockPool()
	defer td()

	go Process(false)
	// Setup the initial subscription message
	mconn.Command("SUBSCRIBE", keySubChannel).
		Expect(createSubscribeMessage(keySubChannel))
	mconn.Command("UNSUBSCRIBE", keySubChannel).
		Expect(createUnsubscribeMessage(keySubChannel))
	mconn.Command("GET", runnerKey).
		Expect("something").
		Expect("somethingelse")
	mconn.ReceiveWait = true

	mconn.AddSubscriptionMessage(createSubscriptionMessage(keySubChannel, runnerKey+"=somethingelse"))

	// ACTUALLY Fill the buffers
	go func(mconn *redigomock.Conn) {
		mconn.ReceiveNow <- true
		mconn.ReceiveNow <- true
		mconn.ReceiveNow <- true
	}(mconn)

	val, err := WatchKey(runnerKey, "something", time.Duration(1*time.Second))
	assert.NoError(t, err, "Expected no error")
	assert.Equal(t, WatchKeyStatusSeenChange, val, "Expected value to change")
}

func TestWatchKeyNoChange(t *testing.T) {
	mconn, td := setupMockPool()
	defer td()

	go Process(false)
	// Setup the initial subscription message
	mconn.Command("SUBSCRIBE", keySubChannel).
		Expect(createSubscribeMessage(keySubChannel))
	mconn.Command("UNSUBSCRIBE", keySubChannel).
		Expect(createUnsubscribeMessage(keySubChannel))
	mconn.Command("GET", runnerKey).
		Expect("something").
		Expect("something")
	mconn.ReceiveWait = true

	mconn.AddSubscriptionMessage(createSubscriptionMessage(keySubChannel, runnerKey+"=something"))

	// ACTUALLY Fill the buffers
	go func(mconn *redigomock.Conn) {
		mconn.ReceiveNow <- true
		mconn.ReceiveNow <- true
		mconn.ReceiveNow <- true
	}(mconn)

	val, err := WatchKey(runnerKey, "something", time.Duration(1*time.Second))
	assert.NoError(t, err, "Expected no error")
	assert.Equal(t, WatchKeyStatusNoChange, val, "Expected notification without change to value")
}

func TestWatchKeyTimeout(t *testing.T) {
	mconn, td := setupMockPool()
	defer td()

	go Process(false)
	// Setup the initial subscription message
	mconn.Command("SUBSCRIBE", keySubChannel).
		Expect(createSubscribeMessage(keySubChannel))
	mconn.Command("UNSUBSCRIBE", keySubChannel).
		Expect(createUnsubscribeMessage(keySubChannel))
	mconn.Command("GET", runnerKey).
		Expect("something").
		Expect("something")
	mconn.ReceiveWait = true

	// ACTUALLY Fill the buffers
	go func(mconn *redigomock.Conn) {
		mconn.ReceiveNow <- true
		mconn.ReceiveNow <- true
		mconn.ReceiveNow <- true
	}(mconn)

	val, err := WatchKey(runnerKey, "something", time.Duration(1*time.Second))
	assert.NoError(t, err, "Expected no error")
	assert.Equal(t, WatchKeyStatusTimeout, val, "Expected value to not change")
}

func TestWatchKeyAlreadyChanged(t *testing.T) {
	mconn, td := setupMockPool()
	defer td()

	go Process(false)
	// Setup the initial subscription message
	mconn.Command("SUBSCRIBE", keySubChannel).
		Expect(createSubscribeMessage(keySubChannel))
	mconn.Command("UNSUBSCRIBE", keySubChannel).
		Expect(createUnsubscribeMessage(keySubChannel))
	mconn.Command("GET", runnerKey).
		Expect("somethingelse").
		Expect("somethingelse")
	mconn.ReceiveWait = true

	// ACTUALLY Fill the buffers
	go func(mconn *redigomock.Conn) {
		mconn.ReceiveNow <- true
		mconn.ReceiveNow <- true
		mconn.ReceiveNow <- true
	}(mconn)

	val, err := WatchKey(runnerKey, "something", time.Duration(1*time.Second))
	assert.NoError(t, err, "Expected no error")
	assert.Equal(t, WatchKeyStatusAlreadyChanged, val, "Expected value to have already changed")
}

func TestWatchKeyMassiveParallel(t *testing.T) {
	mconn, td := setupMockPool()
	defer td()

	go Process(false)
	// Setup the initial subscription message
	mconn.Command("SUBSCRIBE", keySubChannel).
		Expect(createSubscribeMessage(keySubChannel))
	mconn.Command("UNSUBSCRIBE", keySubChannel).
		Expect(createUnsubscribeMessage(keySubChannel))
	getCmd := mconn.Command("GET", runnerKey)
	mconn.ReceiveWait = true

	const runTimes = 100
	for i := 0; i < runTimes; i++ {
		mconn.AddSubscriptionMessage(createSubscriptionMessage(keySubChannel, runnerKey+"=somethingelse"))
		getCmd = getCmd.Expect("something")
	}

	wg := &sync.WaitGroup{}
	// Race-conditions /o/ \o\
	for i := 0; i < runTimes; i++ {
		wg.Add(1)
		go func(mconn *redigomock.Conn) {
			defer wg.Done()
			// ACTUALLY Fill the buffers
			go func(mconn *redigomock.Conn) {
				mconn.ReceiveNow <- true
			}(mconn)

			val, err := WatchKey(runnerKey, "something", time.Duration(1*time.Second))
			assert.NoError(t, err, "Expected no error")
			assert.Equal(t, WatchKeyStatusSeenChange, val, "Expected value to change")
		}(mconn)
	}
	wg.Wait()

}
