defmodule ConduitNSQ.SubPool do
  @moduledoc """
  Supervises all the subscriptions to topics
  """
  use Supervisor

  def child_spec([broker, _, _] = args) do
    %{
      id: name(broker),
      start: {__MODULE__, :start_link, args},
      type: :supervisor
    }
  end

  def start_link(broker, subscribers, opts) do
    Supervisor.start_link(__MODULE__, [broker, subscribers, opts], name: name(broker))
  end

  def init([broker, subscribers, adapter_opts]) do
    children = Enum.map(subscribers, &subscriber(broker, &1, adapter_opts))

    Supervisor.init(children, strategy: :one_for_one)
  end

  def name(broker) do
    Module.concat(broker, Adapter.SubPool)
  end

  defp subscriber(broker, {name, opts}, adapter_opts) do
    topic = Keyword.get(opts, :from)
    channel = Keyword.get(opts, :channel)
    config =
      NSQ.Config
      |> struct(adapter_opts)
      |> struct(opts)
      |> struct(message_handler: &ConduitNSQ.Sub.consume(broker, name, &1, &2))

    {NSQ.Consumer.Supervisor, [topic, channel, config]}
  end
end
