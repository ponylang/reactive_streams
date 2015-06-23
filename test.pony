use "ponytest"

actor Main
  new create(env: Env) =>
    let test = PonyTest(env)
    test(_TestOne)
    test.complete()

class _TestOne is UnitTest
  new iso create() => None
  fun name(): String => "reactive-streams/One"

  fun apply(h: TestHelper): TestResult =>
    let pub = _TestPublisher(h, 1)
    let sub = _TestSubscriber(h, pub)
    pub.test_one(sub)
    LongTest

actor _TestPublisher is ManagedPublisher[U64]
  let _h: TestHelper
  let _mgr: SubscriberManager[U64]
  let _subs: U64

  new create(h: TestHelper, subs: U64, qbounds: U64 = U64.max_value()) =>
    _h = h
    _mgr = Unicast[U64](this, qbounds)
    _subs = subs

  fun ref _subscriber_manager(): SubscriberManager[U64] =>
    _mgr

  be test_one(sub: _TestSubscriber) =>
    if _mgr.subscriber_count() < _subs then
      test_one(sub)
      return
    end

    try
      _h.assert_eq[U64](_mgr.subscriber_count(), _subs)
      _h.assert_eq[U64](_mgr.queue_size(), 0)
      _mgr.publish(1)
      _mgr.publish(2)
      _mgr.publish(3)
      _mgr.publish(4)
      _mgr.publish(5)
    end

    test_one_2(sub)

  be test_one_2(sub: _TestSubscriber) =>
    if _mgr.queue_size() > 0 then
      test_one_2(sub)
    else
      sub.test_one_2()
    end

actor _TestSubscriber is Subscriber[U64]
  let _h: TestHelper
  let _pub: _TestPublisher
  var _sub: Subscription = NoSubscription
  var _sum: U64 = 0

  new create(h: TestHelper, pub: _TestPublisher) =>
    _h = h
    _pub = pub
    _pub.subscribe(this)

  be on_subscribe(sub: Subscription iso) =>
    _sub = consume sub
    _sub.request(1)

  be on_next(i: U64) =>
    _sum = _sum + i
    _sub.request(1)

  be test_one_2() =>
    try
      _h.assert_eq[U64](_sum, 15)
    end

    _h.complete(true)
