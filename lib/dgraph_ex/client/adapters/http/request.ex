defmodule DgraphEx.Client.Adapters.HTTP.Request do
  @moduledoc """
  Just the HTTPoison client and main request function

  Can be overridden via the `:exec` config option
  """

  use HTTPoison.Base
  alias DgraphEx.Client.{Adapters, Base, Response}
  alias Adapters.HTTP.RequestBase
  alias Response
  require OK

  @behaviour RequestBase

  @endpoint Application.get_env(:dgraph_ex, :endpoint, "http://localhost:8080")
  @headers Application.get_env(:dgraph_ex, :headers, %{})
  @hackney_opts Application.get_env(:dgraph_ex, :hackney, pool: :dgraph_ex_pool)

  @doc """
  Executes the Dgraph operation over HTTP

  Can be overridden via the `:exec` option in the `:dgraph_ex` config
  """
  @spec exec(url :: bitstring, body :: bitstring, headers :: map) ::
          {:ok, Base.response()} | {:error, Base.error()}
  def exec(url, body, headers \\ %{}) do
    OK.with do
      res <- __MODULE__.post(url, body, headers, hackney: @hackney_opts)
      process_response(res)
    else
      %HTTPoison.Error{reason: reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc """
  Transforms an HTTPoison.Response struct into a Response struct result tuple
  """
  @spec process_response(res :: %HTTPoison.Response{}) ::
          {:ok, Base.response()} | {:error, Base.error()}
  def process_response(%HTTPoison.Response{body: body}) do
    case Poison.decode(body) do
      {:ok, response} ->
        case Map.get(response, "errors", []) do
          [] ->
            {:ok, from_response(response)}

          errors when is_list(errors) ->
            {:error, {:dgraph_error, errors}}
        end

      _ ->
        {:error, :cannot_process_response}
    end
  end

  def process_response(_), do: {:error, :invalid_response}

  @spec from_response(response :: %{optional(bitstring) => any}) :: Base.response()
  defp from_response(response) when is_map(response) do
    data = Map.get(response, "data", %{})

    %Response{
      data: data,
      code: Map.get(data, "code", ""),
      message: Map.get(data, "message", ""),
      uids: Map.get(data, "uids", %{}),
      extensions: Map.get(response, "extensions", %{}),
      errors: Map.get(response, "errors", [])
    }
  end

  @spec list_to_map(klist :: list) :: map
  defp list_to_map(klist) when is_list(klist) do
    Enum.reduce(klist, %{}, &Map.put(&1, elem(&2, 0), elem(&2, 1)))
  end

  ##############################################################################
  # HTTPOISON OVERRIDES
  ##############################################################################

  def process_url(url), do: @endpoint <> url

  def process_request_headers(nil), do: []

  def process_request_headers(headers) when is_list(headers) do
    headers
    |> list_to_map
    |> process_request_headers
  end

  def process_request_headers(headers) when is_map(headers) do
    @headers
    |> Map.merge(headers)
    |> Map.to_list()
  end
end
