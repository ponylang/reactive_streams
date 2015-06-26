use "collections"

class Unicast[A: Any tag]
  """
  Send data to a single subscriber.
  """
  let _pub: ManagedPublisher[A]
  var _sub: (Subscriber[A] | None) = None
  var _request: U64 = 0
  let _queue: List[A] = _queue.create()
  let _qbound: U64

  new create(pub: ManagedPublisher[A], qbound: U64 = U64.max_value()) =>
    """
    Create a Unicast for a given ManagedPublisher.
    """
    _pub = pub
    _qbound = if qbound == 0 then 1 else qbound end

  fun min_request(): U64 =>
    """
    Returns the lowest request count of all subscribers.
    """
    _request

  fun max_request(): U64 =>
    """
    Returns the highest request count of all subscribers.
    """
    _request

  fun queue_bound(): U64 =>
    """
    Returns the queue bound.
    """
    _qbound

  fun queue_size(): U64 =>
    """
    Returns the current queue size.
    """
    _queue.size()

  fun subscriber_count(): U64 =>
    """
    Returns the current subscriber count.
    """
    if _sub is None then 0 else 1 end

  fun ref publish(a: A) =>
    """
    Send data to the subscriber.
    """
    try
      let sub = _sub as Subscriber[A]

      if _request > 0 then
        _request = _request - 1
        sub.on_next(a)
      else
        if _queue.size() == _qbound then
          _queue.shift()
        end

        _queue.push(a)
      end
    end

  fun ref on_complete() =>
    """
    A ManagedPublisher should call this when it has no more data to produce.
    """
    try
      let sub = _sub as Subscriber[A]
      sub.on_complete()
      _sub = None
      _request = 0
    end

    _queue.clear()

  fun ref on_error(e: ReactiveError) =>
    """
    A ManagedPublisher should call this when its internal state has resulted in
    an error that should be propagated to all subscribers.
    """
    try
      let sub = _sub as Subscriber[A]
      sub.on_error(e)
      _sub = None
      _request = 0
    end

    _queue.clear()

  fun ref on_subscribe(sub: Subscriber[A]) =>
    """
    A ManagedPublisher should call this when it receives Publisher.subscribe.
    """
    if _sub is None then
      _sub = sub
      sub.on_subscribe(_Subscription[A](sub, _pub))
    elseif _sub is sub then
      _request = 0
      _queue.clear()

      sub.on_error(SubscribedAlready)
      sub.on_subscribe(_Subscription[A](sub, _pub))
    else
      let subscription = _Subscription[A](sub, _pub)
      subscription.cancel()
      sub.on_subscribe(consume subscription)
      sub.on_error(PublisherFull)
    end

  fun ref on_request(sub: Subscriber[A], n: U64) =>
    """
    A ManagedPublisher should call this when it receives
    ManagedPublisher._on_request.
    """
    if sub is _sub then
      _request = _request + n

      while (_queue.size() > 0) and (_request > 0) do
        try
          sub.on_next(_queue.shift())
          _request = _request - 1
        end
      end
    end

  fun ref on_cancel(sub: Subscriber[A]) =>
    """
    A ManagedPublisher should call this when it receives
    ManagedPublisher._on_cancel.
    """
    if sub is _sub then
      _sub = None
      _request = 0
      _queue.clear()
    end
