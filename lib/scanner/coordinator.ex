defmodule Scanner.Coordinator do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, "ttyAMA0", opts)
  end

  def init(port) do
    #Start the NERVES port
    begin_serial(port)

    # Start httpoison
    HTTPoison.start()

    # Start the polling
    send(self(), :ethernet_check)

    {:ok, %{ id: nil }}
  end

  def handle_info(:ethernet_check, _) do
    case Nerves.Network.status("wlan0") do
      %{is_up: true} -> { :noreply, %{ id: retrieve_id() }}
      _ ->
        :timer.sleep(2000)
        send(self(), :ethernet_check)
        { :noreply, %{ id: nil } }
    end
  end


  def handle_info(_, %{id: nil} = state) do
    Logger.error "No ID in state... doing nothing,"
    {:noreply, state}
  end

  def handle_info({:nerves_uart, _pid, barcode}, %{id: id}) do
    # Check the barcode
    todo_title = case Scanner.UpcDatabaseApi.lookup(barcode) do
      {:ok, product_map} -> get_best_name(product_map, barcode)
      _ -> "Barcode error: #{barcode}"
    end

    # Post the item
    Scanner.WunderlistApi.create_todo(id, todo_title)
    Logger.info "Got info: #{barcode}. Posted item: #{todo_title}"

    # Keep the state constant
    {:noreply, %{ id: id }}
  end

  defp get_best_name(product_map, barcode) do
    try_item_title(product_map)
    |> try_item_description()
    |> fallback_to_barcode(barcode)
  end

  defp try_item_title(product_map) do
    case Map.fetch(product_map, "title") do
      {:ok, ""} -> {:error, product_map}
      {:ok, title} -> {:ok, title}
      _ -> {:error, product_map}
    end
  end

  defp try_item_description({:error, product_map}) do
    case Map.fetch(product_map, :description) do
      {:ok, ""} -> {:error, product_map}
      {:ok, description} -> {:ok, description}
      _ -> {:error, product_map}
    end
  end

  defp try_item_description(passthrough), do: passthrough

  defp fallback_to_barcode({:ok, title}, _), do: title
  defp fallback_to_barcode(_, barcode), do: "Barcode error: #{barcode}"

  defp begin_serial(port) do
    {:ok, pid} = Nerves.UART.start_link
    Nerves.UART.open(pid, port, speed: 9600, active: true)
    Nerves.UART.configure(pid, framing: {Nerves.UART.Framing.Line, separator: "\r\n"})

    pid
  end

  defp retrieve_id() do
    response = Application.get_env(:scanner, :list_name)
      |> Scanner.WunderlistApi.find_list_id()

    case response do
      {:ok, id} -> id
      {:error, error} ->
        Logger.error error.reason
        nil
    end
  end
end
