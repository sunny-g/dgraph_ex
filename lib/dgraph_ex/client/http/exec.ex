defmodule DgraphEx.Client.HTTP.Exec do
  @moduledoc """
  Just the HTTPoison client and main request function

  Can be overridden via the `:exec` config option
  """

  use HTTPoison.Base
  alias DgraphEx.Client.{Base, HTTP, Response}
  alias HTTP.ExecBase
  alias Response
  require OK

  @behaviour ExecBase

  @endpoint Application.get_env(:dgraph_ex, :endpoint, "http://localhost:8080")
  @headers Application.get_env(:dgraph_ex, :headers, %{})
  @hackney_opts Application.get_env(:dgraph_ex, :hackney_opts, pool: :dgraph_ex_pool)

  @doc """
  Executes the HTTP call to Dgraph

  Can be overridden via the `:exec` option in the `:dgraph_ex` config
  """
  @spec exec(url :: bitstring, body :: bitstring, headers :: map) ::
          {:ok, Base.response()} | {:error, Base.error()}
  def exec(url, body, headers \\ %{}) do
    OK.with do
      res <- __MODULE__.post(url, body, headers, hackney: @hackney_opts)
      process_response(res)
    else
      %HTTPoison.Error{reason: reason} -> {:error, reason}
    end
  end

  @doc false
  @spec process_response(res :: %HTTPoison.Response{}) ::
          {:ok, Base.response()} | {:error, Base.error()}
  defp process_response(%HTTPoison.Response{body: body}) do
    response =
      OK.with do
        parsed_body <- Poison.decode(body)
        Map.merge(%Response{}, parsed_body)
      end

    case response do
      {:ok, %Response{errors: []}} ->
        {:ok, response}

      {:ok, %Response{errors: errors}} ->
        {:error, errors}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp process_response(_), do: {:error, :invalid_response}

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
