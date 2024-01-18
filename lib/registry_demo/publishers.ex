defmodule RegistryDemo.Publishers do
  @moduledoc false

  use Supervisor

  alias RegistryDemo.Publishers.Worker
  alias RegistryDemo.Publishers.SubscriberRegistry
  alias RegistryDemo.Publishers.WorkerRegistry

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_init_arg) do
    children =
      [
        {Registry, keys: :unique, name: WorkerRegistry},
        {Registry, keys: :duplicate, name: SubscriberRegistry},
        {DynamicSupervisor, name: WorkerSupervisor}
      ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def subscribe_to(publisher_name, from \\ self()) do
    with :ok <- ensure_started(publisher_name) do
      register_subscription(publisher_name, from)
    end
  end

  defp register_subscription(publisher_name, from) do
    case Registry.register(SubscriberRegistry, publisher_name, from) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_registered, _pid}} ->
        :ok
    end
  end

  defdelegate broadcast(name), to: Worker

  defp ensure_started(name) do
    child_spec = {Worker, name: name}

    case DynamicSupervisor.start_child(WorkerSupervisor, child_spec) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end
