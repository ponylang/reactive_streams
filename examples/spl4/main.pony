use "../../reactive_streams"
use "time"
use "collections"
use @printf[I32](fmt: Pointer[U8] tag, ...)

primitive Defaults
  fun tag items(): U64 => 1000//1 << 20
  fun tag producers(): U64 => 32
  fun tag processors(): U64 => 32
  fun tag consumers(): U64 => 32
  fun tag cap(): U64 => 256
  fun tag sinks(): U64 => producers() * processors() * consumers()
  fun tag nexts(): F64 => items().f64() * sinks().f64()

actor Main
  let _env: Env
  var start: U64 = 0
  var repetitions: U64 = 16
  var arrived: U64 = 0

  new create(env: Env) =>
    _env = env
    restart()

  be arrive() =>
    arrived = arrived + 1

    if arrived == Defaults.sinks() then
      restart()

      let elapsed = Time.nanos() - start
      let secs = elapsed.f64() / F64(1000 * 1000 * 1000)
      let ips = (Defaults.nexts() / secs).u64()

      _env.out.print("Time: " + secs.string())
      _env.out.print(" items per sec: " + ips.string())

      arrived = 0
    end

  be restart() =>
    start = Time.nanos()

    if (repetitions = repetitions - 1) > 1 then
      for prod in Range[U64](0, Defaults.producers()) do
        Pub.compute(this)
      end
    end

actor Sub is Subscriber[Bool]
  let _main: Main
  var _count: U64 = 0
  var _sub: Subscription = NoSubscription

  new create(main: Main) =>
    _main = main

  be on_subscribe(s: Subscription iso) =>
    _sub = consume s
    _sub.request(Defaults.cap())

  be on_next(a: Bool) =>
    _count = _count + 1

    if ((_count and ((Defaults.cap() >> 1) - 1)) == 0) then
      _sub.request(Defaults.cap() >> 1)
    end

  be on_complete() =>
    _main.arrive()

  be on_error(e: ReactiveError) =>
    None

actor Proc is ManagedPublisher[Bool]
  let _broadcast: Broadcast[Bool]
  var _sub: Subscription = NoSubscription
  var _count: U64 = 0

  new create() =>
    _broadcast = Broadcast[Bool](this, Defaults.cap())

  fun ref _subscriber_manager(): SubscriberManager[Bool] =>
    _broadcast

  be on_subscribe(s: Subscription iso) =>
    _sub = consume s
    _sub.request(Defaults.cap())

  be on_next(a: Bool) =>
    _count = _count + 1

    if (_count and ((Defaults.cap() >> 1) - 1)) == 0 then
      _sub.request(Defaults.cap() >> 1)
    end

    _broadcast.publish(a)

    if _broadcast.queue_size() > 0 then
      @printf[I32]("PUB %p queue %lu\n".cstring(),
        this, _broadcast.queue_size())
    end

  be on_error(e: ReactiveError) => None

  be on_complete() => _broadcast.on_complete()

  be attach_to(pub: Pub) => pub.subscribe(this)

actor Pub is ManagedPublisher[Bool]
  let _broadcast: Broadcast[Bool]
  var _remaining: U64

  new compute(main: Main) =>
    _broadcast = Broadcast[Bool](this, Defaults.cap())
    _remaining = Defaults.items()

    for j in Range[U64](0, Defaults.processors()) do
      let t = Proc
      for i in Range[U64](0, Defaults.consumers()) do
        t.subscribe(Sub(main))
      end
      t.attach_to(this)
    end

  be on_request(s: Subscriber[Bool], n: U64) =>
    _broadcast.on_request(s, n)

    if _broadcast.subscriber_count() == Defaults.processors() then
      let send = _remaining.min(_broadcast.min_request())

      if send > 0 then
        _remaining = _remaining - send

        for i in Range[U64](0, send) do
          _broadcast.publish(true)
        end

        if _remaining == 0 then
          _broadcast.on_complete()
        end
      end
    end

  fun ref _subscriber_manager(): SubscriberManager[Bool] =>
    _broadcast
