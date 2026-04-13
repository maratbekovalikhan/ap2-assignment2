package stream

import (
	"sync"
	"time"
)

type Update struct {
	OrderID   string
	Status    string
	UpdatedAt time.Time
}

type Notifier struct {
	mu          sync.RWMutex
	subscribers map[string]map[chan Update]struct{}
}

func NewNotifier() *Notifier {
	return &Notifier{
		subscribers: make(map[string]map[chan Update]struct{}),
	}
}

func (n *Notifier) Subscribe(orderID string) (<-chan Update, func()) {
	ch := make(chan Update, 1)

	n.mu.Lock()
	if _, ok := n.subscribers[orderID]; !ok {
		n.subscribers[orderID] = make(map[chan Update]struct{})
	}
	n.subscribers[orderID][ch] = struct{}{}
	n.mu.Unlock()

	cancel := func() {
		n.mu.Lock()
		defer n.mu.Unlock()

		if subs, ok := n.subscribers[orderID]; ok {
			delete(subs, ch)
			if len(subs) == 0 {
				delete(n.subscribers, orderID)
			}
		}
		close(ch)
	}

	return ch, cancel
}

func (n *Notifier) Notify(update Update) {
	n.mu.RLock()
	defer n.mu.RUnlock()

	for ch := range n.subscribers[update.OrderID] {
		select {
		case ch <- update:
		default:
		}
	}
}
