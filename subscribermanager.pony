interface SubscriberManager[A: Any tag]
  """
  Manages a subscriber list.
  """
  fun min_request(): U64
    """
    Returns the lowest request count of all subscribers.
    """

  fun max_request(): U64
    """
    Returns the highest request count of all subscribers.
    """

  fun queue_bound(): U64
    """
    Returns the queue bound.
    """

  fun queue_size(): U64
    """
    Returns the current queue size.
    """

  fun subscriber_count(): U64
    """
    Returns the current subscriber count.
    """

  fun ref publish(a: A)
    """
    A ManagedPublisher should call this when it has data to publish.
    Subscribers with pending demand will be sent the data immediately. If any
    subscribers with no pending demand exist, the data will be kept on a
    queue to be sent when subscribers request additional data.

    The queue size can be bounded. If so, undelivered old data will be dropped
    if new data must be queued and the queue has hit its size limit.
    """

  fun ref on_complete()
    """
    A ManagedPublisher should call this when it has no more data to produce.
    """

  fun ref on_error(e: ReactiveError)
    """
    A ManagedPublisher should call this when its internal state has resulted in
    an error that should be propagated to all subscribers.
    """

  fun ref on_subscribe(sub: Subscriber[A])
    """
    A ManagedPublisher should call this when it receives Publisher.subscribe.
    """

  fun ref on_request(sub: Subscriber[A], n: U64)
    """
    A ManagedPublisher should call this when it receives
    ManagedPublisher._on_request.
    """

  fun ref on_cancel(sub: Subscriber[A])
    """
    A ManagedPublisher should call this when it receives
    ManagedPublisher._on_cancel.
    """

class _Subscription[A: Any tag] iso is Subscription
  """
  Implements Subscription[A], allowing a subscriber to a ManagedPublisher to
  request more data or cancel its subscription.
  """
  let _sub: Subscriber[A]
  let _pub: ManagedPublisher[A]
  var _cancelled: Bool = false

  new iso create(sub: Subscriber[A], pub: ManagedPublisher[A]) =>
    """
    Create a _Subscription for a given subscriber and publisher.
    """
    _sub = sub
    _pub = pub

  fun ref request(n: U64) =>
    """
    Request more data. NOP if the subscription has been cancelled.
    """
    if not _cancelled and (n > 0) then
      _pub.on_request(_sub, n)
    end

  fun ref cancel() =>
    """
    Cancel the subscription. NOP if it has already been cancelled.
    """
    if not _cancelled then
      _cancelled = true
      _pub.on_cancel(_sub)
    end
