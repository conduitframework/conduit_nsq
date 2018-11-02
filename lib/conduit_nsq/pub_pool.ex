defmodule ConduitNSQ.PubPool do
  @moduledoc """
  Supervises the pool of publishers
  """

  def child_spec([broker, opts]) do
    pool_name = name(broker)
    config = struct(NSQ.Config, opts)
    default_topic = Keyword.get(opts, :default_topic, "--default--")

    pub_pool_opts = [
      name: {:local, pool_name},
      worker_module: NSQ.Producer.Supervisor,
      size: opts[:pub_pool_size] || 5,
      max_overflow: 0
    ]

    %{
      id: name(broker),
      start: {:poolboy, :start_link, [pub_pool_opts, [default_topic, config]]},
      type: :supervisor
    }
  end

  def name(broker) do
    Module.concat(broker, Adapter.PubPool)
  end
end
