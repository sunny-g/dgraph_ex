defmodule DgraphEx.Client.HTTP do
  @moduledoc """
  The HTTP Client for Dgraph (just makes the raw requests over REST)

  Configuration options (under key `:dgraph_ex`):
    - `:endpoint`: URL of the Dgraph database
    - `:abort_path`, `:alter_path`, `:commit_path`, `:mutate_path` and `:query_path`: URL suffixes appended to the endpoint for each operation
    - `:headers`: custom headers to be merged in with each request
    - `:exec`: custom HTTP post function, used mainly for testing (defaults to `HTTPoison.post/4`)
  """

  import DgraphEx.Util, only: [merge_keyword_lists: 2]
  alias DgraphEx.Client

  alias DgraphEx.Core.{
    Alter,
    Delete,
    Field,
    Kwargs,
    Query,
    Set,
    Vertex
  }

  alias Client.{HTTP, LinRead, Transaction}
  alias Client.Base, as: ClientBase
  alias HTTP.Request, as: DefaultRequest
  alias Poison
  require Transaction, as: Tx
  require OK

  @behaviour ClientBase

  @var_prefix "$"
  @header_commitnow "X-Dgraph-CommitNow"
  @header_lin_read "X-Dgraph-LinRead"
  @header_vars "X-Dgraph-Vars"
  @default_commit_opts [txid: -1]
  @default_mutate_opts [txid: -1, commit_now: false, lin_read: %{}]
  @default_query_opts [lin_read: %{}]

  @alter_path Application.get_env(:dgraph_ex, :alter_path, "/alter")
  @mutate_path Application.get_env(:dgraph_ex, :mutate_path, "/mutate")
  @query_path Application.get_env(:dgraph_ex, :query_path, "/query")
  @abort_path Application.get_env(:dgraph_ex, :abort_path, "/abort")
  @commit_path Application.get_env(:dgraph_ex, :commit_path, "/commit")
  @request Application.get_env(:dgraph_ex, :request, DefaultRequest)

  defguard are_query_vars(vars)
           when (is_map(vars) and map_size(vars) > 0) or is_list(vars)

  @spec alter(alteration :: ClientBase.alter_input()) ::
          {:ok, ClientBase.response()} | {:error, ClientBase.error()}

  def alter(:drop_all), do: alter(~s({"drop_all":true}))

  def alter({:drop_attr, attr}) when is_atom(attr) do
    alter(~s({"drop_attr":"#{Atom.to_string(attr)}"))
  end

  def alter({:drop_attr, attr}) when is_bitstring(attr) do
    alter(~s({"drop_attr":"#{attr}"}))
  end

  def alter([%Field{} | _] = fields) do
    alteration = Alter.new(fields)
    alter(alteration)
  end

  def alter(%Alter{} = alter_obj) do
    alteration = Alter.render(alter_obj)
    alter(alteration)
  end

  def alter(module) when is_atom(module) do
    if Vertex.is_model?(module) do
      alteration = Alter.new(module.__vertex__(:fields))
      alter(alteration)
    else
      {:error, :invalid_vertex_model}
    end
  end

  def alter(alteration) when is_bitstring(alteration) do
    make_request(@alter_path, alteration)
  end

  def alter(_), do: {:error, :invalid_alteration}

  @spec mutate(mutation :: ClientBase.mutate_input(), opts :: ClientBase.mutate_opts()) ::
          {:ok, ClientBase.response()} | {:error, ClientBase.error()}
  def mutate(%Set{} = mutation, opts) do
    mutation_str = Set.render(mutation)
    mutate(mutation_str, opts)
  end

  def mutate(%Delete{} = mutation, opts) do
    mutation_str = Delete.render(mutation)
    mutate(mutation_str, opts)
  end

  def mutate(mutation, opts) when is_bitstring(mutation) and is_list(opts) do
    opts = merge_keyword_lists(@default_mutate_opts, opts)
    path = get_path(@mutate_path, opts)

    if path == @mutate_path do
      {:error, :invalid_txid}
    else
      OK.with do
        headers <- get_mutate_headers(opts)
        make_request(path, mutation, headers, opts)
      end
    end
  end

  def mutate(_, _), do: {:error, :invalid_mutation}

  @spec query(query :: ClientBase.query_input(), opts :: ClientBase.query_opts()) ::
          {:ok, ClientBase.response()} | {:error, ClientBase.error()}
  def query(query, opts \\ [])

  def query(kwargs, opts) when is_list(kwargs) do
    query_body = Kwargs.parse(kwargs)
    query(query_body, opts)
  end

  def query(%Query{} = query_obj, opts) do
    query_body = Query.render(query_obj)
    query(query_body, opts)
  end

  def query(query_str, opts) when is_bitstring(query_str) do
    make_request(@query_path, query_str, %{}, opts)
  end

  def query({query_template, vars}, opts)
      when is_bitstring(query_template) and are_query_vars(vars) do
    opts = merge_keyword_lists(@default_query_opts, opts)

    OK.with do
      var_str <- encode_vars(vars)
      headers = %{@header_vars => var_str}
      make_request(@query_path, query_template, headers, opts)
    end
  end

  def query(_, _), do: {:error, :invalid_query}

  @spec abort(txid :: ClientBase.abort_input()) ::
          {:ok, ClientBase.response()} | {:error, ClientBase.error()}
  def abort(txid) when Tx.is_id(txid) do
    path = get_path(@abort_path, txid: txid)
    make_request(path, "")
  end

  def abort(_), do: {:error, :invalid_txid}

  @spec commit(
          keys :: ClientBase.commit_input(),
          opts :: ClientBase.commit_opts()
        ) :: {:ok, ClientBase.response()} | {:error, ClientBase.error()}
  def commit(keys, opts) when is_list(keys) and is_list(opts) do
    opts = merge_keyword_lists(@default_commit_opts, opts)
    path = get_path(@commit_path, opts)

    if path == @commit_path do
      {:error, :invalid_txid}
    else
      OK.with do
        keys_str <- encode_keys(keys)
        make_request(path, keys_str)
      end
    end
  end

  def commit(_, _), do: {:error, :invalid_commit}

  ##############################################################################
  # PRIVATE
  ##############################################################################

  @spec get_path(root :: bitstring, opts :: ClientBase.mutate_opts()) :: HTTPoison.url()
  defp get_path(root, [{:txid, -1} | _]), do: root

  defp get_path(root, [{:txid, txid} | _]) when Tx.is_id(txid) do
    root <> "/" <> Integer.to_string(txid)
  end

  @spec get_mutate_headers(opts :: ClientBase.mutate_opts()) ::
          {:ok, map} | {:error, :invalid_txid}
  defp get_mutate_headers([{:txid, _}, {:commit_now, false} | _]) do
    {:ok, %{}}
  end

  defp get_mutate_headers([{:txid, txid}, {:commit_now, true} | _])
       when Tx.is_id(txid),
       do: {:ok, %{@header_commitnow => true}}

  defp get_mutate_headers([{:txid, _}, {:commit_now, _} | _]) do
    {:error, :invalid_txid}
  end

  @spec encode_keys(keys :: Tx.keys()) :: {:ok, bitstring} | {:error, any}
  defp encode_keys(keys) when is_list(keys), do: Poison.encode(keys)
  defp encode_keys(_keys), do: {:error, :invalid_keys}

  @spec encode_vars(vars :: ClientBase.query_vars()) :: {:ok, bitstring} | {:error, any}
  defp encode_vars(vars) do
    vars
    |> Enum.map(fn {k, v} -> {encode_var_key(k), encode_var_val(v)} end)
    |> Enum.into(%{})
    |> Poison.encode()
  end

  defp encode_var_key(k) when is_atom(k), do: @var_prefix <> Atom.to_string(k)
  defp encode_var_key(str) when is_bitstring(str), do: @var_prefix <> str

  defp encode_var_val(nil), do: "null"
  defp encode_var_val(val) when is_atom(val), do: Atom.to_string(val)
  defp encode_var_val(val) when is_float(val), do: Float.to_string(val)
  defp encode_var_val(val) when is_integer(val), do: Integer.to_string(val)
  defp encode_var_val(val) when is_bitstring(val), do: val

  @spec make_request(url :: bitstring, body :: bitstring) ::
          {:ok, ClientBase.response()} | {:error, ClientBase.error()}
  @spec make_request(url :: bitstring, body :: bitstring, headers :: map) ::
          {:ok, ClientBase.response()} | {:error, ClientBase.error()}
  @spec make_request(
          url :: bitstring,
          body :: bitstring,
          headers :: map,
          opts :: ClientBase.send_opts()
        ) :: {:ok, ClientBase.response()} | {:error, ClientBase.error()}
  defp make_request(url, body), do: __do_request__(url, body)

  defp make_request(url, body, headers, opts \\ []) do
    case Keyword.get(opts, :lin_read, %{}) do
      lin_read when map_size(lin_read) == 0 ->
        __do_request__(url, body, headers)

      lin_read ->
        OK.with do
          lin_read_string <- LinRead.encode(lin_read)
          headers = Map.merge(headers, %{@header_lin_read => lin_read_string})
          __do_request__(url, body, headers)
        end
    end
  end

  @doc "Executes the underlying REST request against a mockable module"
  @spec __do_request__(url :: bitstring, body :: bitstring, headers :: map) ::
          {:ok, ClientBase.response()} | {:error, ClientBase.error()}
  def __do_request__(url, body, headers \\ %{}) do
    @request.exec(url, body, headers)
  end
end
