defmodule ConduitNSQ.Sub do
  @moduledoc """
  Supervises all the subscriptions to topics
  """

  alias Conduit.Message

  def consume(broker, name, body, message) do
    %Message{}
    |> Message.put_body(body)
    |> Message.put_private(:nsq_message, message)
    |> broker.receives(name)
  end
end
