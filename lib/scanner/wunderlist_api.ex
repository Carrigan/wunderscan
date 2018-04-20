defmodule Scanner.WunderlistApi do
  require Logger

  def find_list_id(title) do
    uri("/lists")
    |> HTTPoison.get(auth_headers(), hackney: [:insecure])
    |> process_response(title)
  end

  def create_todo(list_id, title) do
    todo_body = Poison.encode!(%{ "list_id" => list_id, "title" => title })

    response = uri("/tasks")
    |> HTTPoison.post(todo_body, auth_headers() ++ ["Content-Type": "application/json"], hackney: [:insecure])
  end

  def process_response({:ok, %HTTPoison.Response{body: body}}, title) do
    Poison.decode!(body)
    |> Enum.find(%{}, fn list_item -> Map.get(list_item, "title") == title end)
    |> Map.fetch("id")
  end

  def process_response(error, _), do: error

  defp uri(suffix) do
    "https://a.wunderlist.com/api/v1" <> suffix
  end

  defp auth_headers() do
    [
      "X-Access-Token": Application.get_env(:scanner, :wunderlist_access_key),
      "X-Client-Id": Application.get_env(:scanner, :wunderlist_client_id)
    ]
  end
end
