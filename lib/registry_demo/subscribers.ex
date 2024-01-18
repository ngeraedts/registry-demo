defmodule RegistryDemo.Subscribers do
  @moduledoc false

  use Supervisor

  alias RegistryDemo.Subscribers.Worker
  alias RegistryDemo.Subscribers.SubscriberRegistry
  alias RegistryDemo.Subscribers.SubscriberSupervisor

  require Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_arg) do
    children =
      [
        {Registry, keys: :unique, name: SubscriberRegistry},
        {DynamicSupervisor, name: SubscriberSupervisor}
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def subscribe_to(name, publisher_name) do
    with :ok <- ensure_started(name) do
      Worker.subscribe_to(name, publisher_name)
    end
  end

  def cancel_all_subscriptions(name) do
    Worker.shutdown(name)
  end

  defp ensure_started(name) do
    child_spec = {Worker, name: name}

    case DynamicSupervisor.start_child(SubscriberSupervisor, child_spec) do
      {:ok, _pid} ->
        Logger.debug("started #{name}")
        :ok

      {:error, {:already_started, _pid}} ->
        Logger.debug("#{name} already started")
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end
