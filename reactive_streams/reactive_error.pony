trait val ReactiveError
  """
  Marker trait for errors propagated through a reactive stream.
  """

primitive SubscribedAlready is ReactiveError
  """
  The subscriber has already subscribed to this publisher.
  """

primitive PublisherFull is ReactiveError
  """
  The publisher cannot accept any more subscribers.
  """
