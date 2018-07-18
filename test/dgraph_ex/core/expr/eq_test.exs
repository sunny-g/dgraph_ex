defmodule DgraphEx.Core.Expr.EqTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Core.Expr.Eq

  import DgraphEx
  alias DgraphEx.Core.Expr.Eq

  test "render eq with predicate, literal, and type" do
    assert eq(:beef, "cow bull moo", :string) |> Eq.render() == "eq(beef, \"cow bull moo\")"
  end

  test "render eq with predicate and literal, no type" do
    assert eq(:beef, "cow bull moo") |> Eq.render() == "eq(beef, \"cow bull moo\")"
  end

  test "render eq with val and literal" do
    assert eq(val(:c), "cow bull moo") |> Eq.render() == "eq(val(c), \"cow bull moo\")"
  end

  test "render eq with count and literal" do
    assert eq(count(:friend), 10) |> Eq.render() == "eq(count(friend), 10)"
  end

  test "render eq with predicate and list" do
    assert eq(:fav_color, ["blue", "green", "brown"]) |> Eq.render() ==
             ~s{eq(fav_color, ["blue","green","brown"])}
  end
end
