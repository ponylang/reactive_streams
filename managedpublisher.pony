interface ManagedPublisher[A: Any tag] tag is Publisher[A]
  """
  A ManagedPublisher must have a SubscriberManager and give access to it.
  """
  fun ref _subscriber_manager(): SubscriberManager[A]
    """
    Return the SubscriberManager associated with this ManagedPublisher.
    """

  be subscribe(s: Subscriber[A]) =>
    """
    A ManagedPublisher must respond by calling SubscriberManager._on_subscribe.
    """
    _subscriber_manager()._on_subscribe(s)

  be _on_request(s: Subscriber[A], n: U64) =>
    """
    A ManagedPublisher must respond by calling SubscriberManager._on_request.
    """
    _subscriber_manager()._on_request(s, n)

  be _on_cancel(s: Subscriber[A]) =>
    """
    A ManagedPublisher must respond by calling SubscriberManager._on_cancel.
    """
    _subscriber_manager()._on_cancel(s)
