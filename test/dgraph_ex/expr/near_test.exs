defmodule DgraphEx.Expr.NearTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Expr.Near
  import TestHelpers

  import DgraphEx

  test "near renders correctly" do
    assert render(near(:loc, [123.456, 0.1], 1000)) ==
             clean_format("""
               near(loc, [123.456,0.1], 1000)
             """)
  end
end
