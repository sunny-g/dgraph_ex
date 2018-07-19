defmodule DgraphEx.Client.LinRead do
  @moduledoc false

  alias Poison

  @type t :: %{optional(String.t()) => non_neg_integer}

  @doc false
  @spec valid?(lin_read :: t) :: boolean
  def valid?(lin_read) when is_map(lin_read) do
    Enum.all?(lin_read, fn {k, v} -> is_bitstring(k) and is_integer(v) end)
  end

  def valid?(_), do: false

  @doc """
  Serializes the lin_read object to a JSON string
  """
  @spec encode(lin_read :: t) :: {:ok, bitstring} | {:error, any}
  def encode(%{} = lin_read) do
    if valid?(lin_read) do
      Poison.encode(lin_read)
    else
      {:error, :invalid_lin_read}
    end
  end

  @doc """
  Merges two lin_read objects, taking the max value for any duplicate keys
  """
  @spec merge_lin_reads(target :: t, source :: t) :: {:ok, t} | {:error, :invalid_lin_read}
  def merge_lin_reads(%{} = target, %{} = source) do
    if valid?(source) do
      new_lin_read =
        Map.merge(target, source, fn
          _, v1, v2 when v1 > v2 -> v1
          _, v1, v2 when v2 > v1 -> v2
          _, v1, _ -> v1
        end)

      {:ok, new_lin_read}
    else
      {:error, :invalid_lin_read}
    end
  end
end
