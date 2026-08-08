interface tag Processor[A: Any #share, B: Any #share] is
  (Subscriber[A] & Publisher[B])
  """
  A Processor represents a processing stage—which is both a Subscriber and a
  Publisher and obeys the contracts of both.
  """
