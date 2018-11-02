defmodule ConduitNSQ.SubPoolTest do
  use ExUnit.Case
  alias ConduitNSQ.SubPool
  doctest ConduitNSQ.SubPool

  @subscribers %{
    queue_test: [from: "topic1", channel: "my-app", max_in_flight: 20],
    queue_test2: [from: "topic2", channel: "my-app", max_in_flight: 50, rdy_retry_delay: 300]
  }
  @opts [nsqds: ["127.0.0.1:4150"], nsqlookupds: ["127.0.0.1:4160"], rdy_retry_delay: 200]
  describe "init" do
    test "generates the expected child specs" do
      assert {:ok, {adapter_opts, child_specs}} = SubPool.init([Broker, @subscribers, @opts])

      assert adapter_opts == %{intensity: 3, period: 5, strategy: :one_for_one}

      assert child_specs == [
               %{
                 id: NSQ.Consumer.Supervisor,
                 start:
                   {NSQ.Consumer.Supervisor, :start_link,
                    [
                      [
                        "topic1",
                        "my-app",
                        %NSQ.Config{
                          nsqds: ["127.0.0.1:4150"],
                          nsqlookupds: ["127.0.0.1:4160"],
                          max_in_flight: 20,
                          rdy_retry_delay: 200
                        }
                      ]
                    ]},
                 type: :supervisor
               },
               %{
                 id: NSQ.Consumer.Supervisor,
                 start:
                   {NSQ.Consumer.Supervisor, :start_link,
                    [
                      [
                        "topic2",
                        "my-app",
                        %NSQ.Config{
                          nsqds: ["127.0.0.1:4150"],
                          nsqlookupds: ["127.0.0.1:4160"],
                          max_in_flight: 50,
                          rdy_retry_delay: 300
                        }
                      ]
                    ]},
                 type: :supervisor
               }
             ]
    end
  end
end
