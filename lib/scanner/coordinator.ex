defmodule Scanner.Coordinator do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, "ttyAMA0", opts)
  end

  def init(port) do
    {:ok, pid} = Nerves.UART.start_link
    Nerves.UART.open(pid, port, speed: 9600, active: true)
    Nerves.UART.configure(pid, framing: {Nerves.UART.Framing.Line, separator: "\r\n"})

    {:ok, %{}}
  end

  def handle_info({:nerves_uart, _pid, barcode}, state) do
    Logger.info "Got info: #{barcode}"
    {:noreply, state}
  end
end
