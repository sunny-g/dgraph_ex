defmodule DgraphEx.Core.Expr.MathTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Core.Expr.Math
  alias DgraphEx.Core.Expr.Math

  import DgraphEx

  test "math/1 is callable" do
    math(1 + 1)
  end

  test "math/1 renders atoms correctly" do
    assert math(:paths / (:num_films / :paths)) |> Math.render() ==
             "math(paths / (num_films / paths))"
  end

  test "math/1 renders ints correctly" do
    assert math(1) |> Math.render() == "math(1)"
  end

  test "math/1 renders other math too" do
    assert math(logbase(:a, :b)) |> Math.render() == "math(logbase(a, b))"
  end
end
