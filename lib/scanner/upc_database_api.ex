defmodule Scanner.UpcDatabaseApi do
  @required_fields ~w(title description)

  def lookup(upc) do
    HTTPoison.get(uri("/product/0#{upc}"), [], hackney: [:insecure]) |> process_response()
  end

  def process_response({:ok, %HTTPoison.Response{body: body}}) do
    Poison.decode!(body)
    |> build_ok()
  end

  def process_response(error, _), do: error

  defp build_ok(output) do
    {:ok, output}
  end

  defp uri(suffix) do
    "https://api.upcdatabase.org" <> suffix <> access_key()
  end

  defp access_key() do
    "/#{Application.get_env(:scanner, :upcdatabase_access_key)}"
  end
end
