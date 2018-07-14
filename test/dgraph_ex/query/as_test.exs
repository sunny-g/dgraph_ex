defmodule DgraphEx.Query.AsTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Query.As
  import TestHelpers

  import DgraphEx

  test "as function is composable" do
    assert clean_format("""
      {
        bleep as var(func: eq(hands, 2)) {
          legs
        }
      }
    """) == query()
    |> as(:bleep)
    |> func(:var, eq(:hands, 2))
    |> select({ :legs })
    |> render()
  end
end
