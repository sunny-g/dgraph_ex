defmodule DgraphEx.Client.HTTP.RequestBase do
  @moduledoc """
  Base behaviour for the main request function
  """

  alias DgraphEx.Client.Base

  @callback exec(url :: bitstring, body :: bitstring, headers :: map) ::
              {:ok, Base.response()} | {:error, Base.error()}
end
