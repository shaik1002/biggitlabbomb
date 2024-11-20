package redis

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/jpillora/backoff"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/redis/go-redis/v9"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

type KeyWatcher struct {
	mu               sync.Mutex
	subscribers      map[string][]chan string
	shutdown         chan struct{}
	reconnectBackoff backoff.Backoff
	redisConn        *redis.Client // can be nil
	conn             *redis.PubSub
}

func NewKeyWatcher(redisConn *redis.Client) *KeyWatcher {
	return &KeyWatcher{
		shutdown: make(chan struct{}),
		reconnectBackoff: backoff.Backoff{
			Min:    100 * time.Millisecond,
			Max:    60 * time.Second,
			Factor: 2,
			Jitter: true,
		},
		redisConn: redisConn,
	}
}

var (
	KeyWatchers = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_keywatcher_keywatchers",
			Help: "The number of keys that is being watched by gitlab-workhorse",
		},
	)
	RedisSubscriptions = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_keywatcher_redis_subscriptions",
			Help: "Current number of keywatcher Redis pubsub subscriptions",
		},
	)
	TotalMessages = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywatcher_total_messages",
			Help: "How many messages gitlab-workhorse has received in total on pubsub.",
		},
	)
	TotalActions = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywatcher_actions_total",
			Help: "Counts of various keywatcher actions",
		},
		[]string{"action"},
	)
	ReceivedBytes = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_keywatcher_received_bytes_total",
			Help: "How many bytes of messages gitlab-workhorse has received in total on pubsub.",
		},
	)
)

const channelPrefix = "workhorse:notifications:"

func countAction(action string) { TotalActions.WithLabelValues(action).Add(1) }

func (kw *KeyWatcher) receivePubSubStream(ctx context.Context, pubsub *redis.PubSub) error {
	kw.mu.Lock()
	// We must share kw.conn with the goroutines that call SUBSCRIBE and
	// UNSUBSCRIBE because Redis pubsub subscriptions are tied to the
	// connection.
	kw.conn = pubsub
	kw.mu.Unlock()

	defer func() {
		kw.mu.Lock()
		defer kw.mu.Unlock()
		kw.conn.Close()
		kw.conn = nil

		// Reset kw.subscribers because it is tied to Redis server side state of
		// kw.conn and we just closed that connection.
		for _, chans := range kw.subscribers {
			for _, ch := range chans {
				close(ch)
				KeyWatchers.Dec()
			}
		}
		kw.subscribers = nil
	}()

	for {
		msg, err := kw.conn.Receive(ctx)
		if err != nil {
			log.WithError(fmt.Errorf("keywatcher: pubsub receive: %v", err)).Error()
			return nil
		}

		switch msg := msg.(type) {
		case *redis.Subscription:
			RedisSubscriptions.Set(float64(msg.Count))
		case *redis.Pong:
			// Ignore.
		case *redis.Message:
			TotalMessages.Inc()
			ReceivedBytes.Add(float64(len(msg.Payload)))
			if strings.HasPrefix(msg.Channel, channelPrefix) {
				kw.notifySubscribers(msg.Channel[len(channelPrefix):], string(msg.Payload))
			}
		default:
			log.WithError(fmt.Errorf("keywatcher: unknown: %T", msg)).Error()
			return nil
		}
	}
}

func (kw *KeyWatcher) Process() {
	log.Info("keywatcher: starting process loop")

	ctx := context.Background() // lint:allow context.Background

	for {
		pubsub := kw.redisConn.Subscribe(ctx, []string{}...)
		if err := pubsub.Ping(ctx); err != nil {
			log.WithError(fmt.Errorf("keywatcher: %v", err)).Error()
			time.Sleep(kw.reconnectBackoff.Duration())
			continue
		}

		kw.reconnectBackoff.Reset()

		if err := kw.receivePubSubStream(ctx, pubsub); err != nil {
			log.WithError(fmt.Errorf("keywatcher: receivePubSubStream: %v", err)).Error()
		}
	}
}

func (kw *KeyWatcher) Shutdown() {
	log.Info("keywatcher: shutting down")

	kw.mu.Lock()
	defer kw.mu.Unlock()

	select {
	case <-kw.shutdown:
		// already closed
	default:
		close(kw.shutdown)
	}
}

func (kw *KeyWatcher) notifySubscribers(key, value string) {
	kw.mu.Lock()
	defer kw.mu.Unlock()

	chanList, ok := kw.subscribers[key]
	if !ok {
		countAction("drop-message")
		return
	}

	countAction("deliver-message")
	for _, c := range chanList {
		select {
		case c <- value:
		default:
		}
	}
}

func (kw *KeyWatcher) addSubscription(ctx context.Context, key string, notify chan string) error {
	kw.mu.Lock()
	defer kw.mu.Unlock()

	if kw.conn == nil {
		// This can happen because CI long polling is disabled in this Workhorse
		// process. It can also be that we are waiting for the pubsub connection
		// to be established. Either way it is OK to fail fast.
		return errors.New("no redis connection")
	}

	if len(kw.subscribers[key]) == 0 {
		countAction("create-subscription")
		if err := kw.conn.Subscribe(ctx, channelPrefix+key); err != nil {
			return err
		}
	}

	if kw.subscribers == nil {
		kw.subscribers = make(map[string][]chan string)
	}
	kw.subscribers[key] = append(kw.subscribers[key], notify)
	KeyWatchers.Inc()

	return nil
}

func (kw *KeyWatcher) delSubscription(ctx context.Context, key string, notify chan string) {
	kw.mu.Lock()
	defer kw.mu.Unlock()

	chans, ok := kw.subscribers[key]
	if !ok {
		// This can happen if the pubsub connection dropped while we were
		// waiting.
		return
	}

	for i, c := range chans {
		if notify == c {
			kw.subscribers[key] = append(chans[:i], chans[i+1:]...)
			KeyWatchers.Dec()
			break
		}
	}
	if len(kw.subscribers[key]) == 0 {
		delete(kw.subscribers, key)
		countAction("delete-subscription")
		if kw.conn != nil {
			kw.conn.Unsubscribe(ctx, channelPrefix+key)
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

func (kw *KeyWatcher) WatchKey(ctx context.Context, key, value string, timeout time.Duration) (WatchKeyStatus, error) {
	notify := make(chan string, 1)
	if err := kw.addSubscription(ctx, key, notify); err != nil {
		return WatchKeyStatusNoChange, err
	}
	defer kw.delSubscription(ctx, key, notify)

	currentValue, err := kw.redisConn.Get(ctx, key).Result()
	if errors.Is(err, redis.Nil) {
		currentValue = ""
	} else if err != nil {
		return WatchKeyStatusNoChange, fmt.Errorf("keywatcher: redis GET: %v", err)
	}
	if currentValue != value {
		return WatchKeyStatusAlreadyChanged, nil
	}

	select {
	case <-kw.shutdown:
		log.WithFields(log.Fields{"key": key}).Info("stopping watch due to shutdown")
		return WatchKeyStatusNoChange, nil
	case currentValue := <-notify:
		if currentValue == "" {
			return WatchKeyStatusNoChange, fmt.Errorf("keywatcher: redis GET failed")
		}
		if currentValue == value {
			return WatchKeyStatusNoChange, nil
		}
		return WatchKeyStatusSeenChange, nil
	case <-time.After(timeout):
		return WatchKeyStatusTimeout, nil
	}
}
