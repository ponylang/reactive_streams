interface Subscriber[A: Any tag] tag
  """
  Will receive call to on_subscribe once after passing an instance of
  Subscriber to Publisher.subscribe.

  No further notifications will be received until Subscription.request is
  called.

  After signaling demand:

  * One or more invocations of on_next up to the maximum number defined by
    Subscription.request
  * Single invocation of on_error or on_complete which signals a terminal
    state after which no further events will be sent.

  Demand can be signaled via Subscription.request whenever the Subscriber
  instance is capable of handling more.
  """
  be on_subscribe(s: Subscription iso) =>
    """
    Invoked after calling Publisher.subscribe.

    No data will start flowing until Subscription.request is invoked.

    It is the responsibility of this Subscriber instance to call
    Subscription.request whenever more data is wanted.

    The Publisher will send notifications only in response to
    Subscription.request.
    """
    None

  be on_next(a: A) =>
    """
    Data notification sent by the Publisher in response to requests to
    Subscription.request.
    """
    None

  be on_error(/*some error state*/) =>
    """
    Failed terminal state.

    No further events will be sent even if Subscription.request is invoked
    again.
    """
    None

  be on_complete() =>
    """
    Successful terminal state.

    No further events will be sent even if Subscription.request is invoked
    again.
    """
    None
