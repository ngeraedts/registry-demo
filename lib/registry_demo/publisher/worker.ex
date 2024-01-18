defmodule RegistryDemo.Publishers.Worker do
  use GenServer, restart: :transient

  alias RegistryDemo.Publishers.WorkerRegistry
  alias RegistryDemo.Publishers.SubscriberRegistry

  require Logger

  def broadcast(name) do
    GenServer.cast(via(name), :broadcast)
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: via(name))
  end

  @impl GenServer
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    {:ok, %{name: name}}
  end

  @impl GenServer
  def handle_cast(:broadcast, state) do
    now = DateTime.utc_now()
    name = state.name

    Registry.dispatch(SubscriberRegistry, name, fn subscribers ->
      Logger.debug(subscribers, label: "#{name} subscribers")

      Enum.each(subscribers, fn {pid, _} ->
        send(pid, {:broadcast, name, now})
      end)
    end)

    {:noreply, state}
  end

  defp via(name) do
    {:via, Registry, {WorkerRegistry, name}}
  end
end
