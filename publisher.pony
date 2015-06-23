interface Publisher[A: Any tag] tag
  """
  A Publisher is a provider of a potentially unbounded number of sequenced
  elements, publishing them according to the demand received from its
  Subscriber(s).

  A Publisher can serve multiple Subscribers subscribed dynamically at various
  points in time.
  """
  be subscribe(s: Subscriber[A])
    """
    Request Publisher to start streaming data.

    This is a "factory method" and can be called multiple times, each time
    starting a new Subscription.

    Each Subscription will work for only a single Subscriber.

    A Subscriber should only subscribe once to a single Publisher.

    If the Publisher rejects the subscription attempt or otherwise fails it
    will signal the error via Subscriber.on_error.
    """
