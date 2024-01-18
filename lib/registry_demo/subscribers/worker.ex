defmodule RegistryDemo.Subscribers.Worker do
  use GenServer, restart: :transient

  alias RegistryDemo.Subscribers.SubscriberRegistry
  alias RegistryDemo.Publishers

  require Logger

  def subscribe_to(name, publisher) do
    GenServer.call(via(name), {:subscribe_to, publisher})
  end

  def shutdown(name) do
    GenServer.stop(via(name), :normal)
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
  def handle_call({:subscribe_to, publisher_name}, _from, state) do
    :ok = Publishers.subscribe_to(publisher_name)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.info("#{state.name} got msg: #{inspect(msg)}")
    {:noreply, state}
  end

  defp via(name) do
    {:via, Registry, {SubscriberRegistry, name}}
  end
end
