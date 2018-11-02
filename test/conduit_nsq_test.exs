defmodule ConduitNSQTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest ConduitNSQ

  defmodule Broker do
    @moduledoc false
    def receives(_name, message) do
      send(ConduitNSQTest, {:broker, message})

      message
    end
  end

  defmodule OtherBroker do
    @moduledoc false
    def receives(_name, message) do
      send(ConduitNSQTest, {:broker, message})

      message
    end
  end

  @subscribers %{
    queue_test: [from: "topic1", channel: "my-app"],
    queue_test2: [from: "topic2", channel: "my-app"]
  }
  @opts [nsqds: ["127.0.0.1:4150"], nsqlookupds: ["127.0.0.1:4160"]]
  @config struct(NSQ.Config, @opts)
  describe "init" do
    test "warns when topology is specified" do
      log =
        capture_log(fn ->
          ConduitNSQ.init([Broker, [{:queue, "bob", []}], [], []])
        end)

      assert log =~ "Configuring topology is unsupported by this adapter"
    end

    @tag :capture_log
    test "generates expected child specs" do
      {:ok, {adapter_opts, child_specs}} = ConduitNSQ.init([Broker, [], @subscribers, @opts])

      assert adapter_opts == %{intensity: 3, period: 5, strategy: :one_for_one}

      assert child_specs == [
               %{
                 id: ConduitNSQTest.Broker.Adapter.PubPool,
                 start:
                   {:poolboy, :start_link,
                    [
                      [
                        name: {:local, ConduitNSQTest.Broker.Adapter.PubPool},
                        worker_module: NSQ.Producer.Supervisor,
                        size: 5,
                        max_overflow: 0
                      ],
                      ["--default--", @config]
                    ]},
                 type: :supervisor
               },
               %{
                 id: Broker.Adapter.SubPool,
                 start:
                   {ConduitNSQ.SubPool, :start_link,
                    [
                      Broker,
                      @subscribers,
                      @opts
                    ]},
                 type: :supervisor
               }
             ]
    end
  end
end
