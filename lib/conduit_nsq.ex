defmodule ConduitNSQ do
  @moduledoc """
  NSQ adapter for Conduit.
  """

  use Conduit.Adapter
  alias Conduit.Util
  require Logger

  def child_spec([broker, _, _, _] = args) do
    %{
      id: name(broker),
      start: {__MODULE__, :start_link, args},
      type: :supervisor
    }
  end

  @spec name(module()) :: module()
  def name(broker) do
    Module.concat(broker, Adapter)
  end

  @impl true
  def start_link(broker, topology, subscribers, opts) do
    Supervisor.start_link(__MODULE__, [broker, topology, subscribers, opts], name: name(broker))
  end

  def init([broker, topology, subscribers, opts]) do
    Logger.info("NSQ Adapter started!")

    topology_warn(broker, topology)

    children = [
      {ConduitNSQ.PubPool, [broker, opts]},
      {ConduitNSQ.SubPool, [broker, subscribers, opts]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # TODO: Remove when conduit goes to 1.0
  # Conduit will never call this if publish/4 is defined
  @impl true
  def publish(message, _config, _opts) do
    {:ok, message}
  end

  @impl true
  def publish(broker, message, _config, _opts) do
    with_conn(broker, 3, fn conn ->
      NSQ.Producer.pub(conn, message.destination, message.body)
    end)
  end

  defp with_conn(broker, retries, fun) do
    pool = ConduitNSQ.PubPool.name(broker)

    Util.retry([attempts: retries], fn ->
      :poolboy.transaction(pool, fun)
    end)
  end

  defp topology_warn(_, []), do: nil

  defp topology_warn(broker, _) do
    Logger.warn("""
    Configuring topology is unsupported by this adapter. You fix this warning by removing
    the configure block in #{inspect(broker)}")
    """)
  end
end
