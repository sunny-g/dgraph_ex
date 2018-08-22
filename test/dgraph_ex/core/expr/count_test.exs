defmodule DgraphEx.Core.Expr.CountTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Core.Expr.Count
  import TestHelpers

  import DgraphEx

  test "count with simple value" do
    assert render(count(:G)) == clean_format("count(G)")
  end

  test "count with an extra" do
    assert render(count(:G, filter(anyofterms(:name, "Jason")))) ==
             clean_format("""
               count(G @filter(anyofterms(name, \"Jason\")))
             """)
  end

  test "count with two extras" do
    assert render(count(:G, [filter(anyofterms(:name, "Jason")), ignorereflex()])) ==
             clean_format("""
               count(G @filter(anyofterms(name, \"Jason\")) @ignorereflex)
             """)
  end
end
