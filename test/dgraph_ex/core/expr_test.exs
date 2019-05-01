defmodule DgraphEx.Core.ExprTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Core.Expr

  import DgraphEx

  alias DgraphEx.Core.Expr.{
    # indices
    Allofterms,
    Anyofterms,
    Alloftext,
    Anyoftext,
    Regexp,

    # Neq indices
    Ge,
    Gt,
    Le,
    Lt,

    # Aggs
    Agg,
    Avg,
    Max,
    Min,
    Sum,

    # simples
    Val,
    Count,
    Uid,
    Has
  }

  test "render count" do
    assert count(:beef) |> Count.render() == "count(beef)"
  end

  test "render uid as literal" do
    assert uid("0x123") |> Uid.render() == "<0x123>"
  end

  test "render uid as label" do
    assert uid(:beef) |> Uid.render() == "uid(beef)"
  end

  test "render allofterms" do
    assert allofterms(:beef, "cow bull moo") |> Allofterms.render() ==
             "allofterms(beef, \"cow bull moo\")"
  end

  test "render val" do
    assert val(:my_var) |> Val.render() == "val(my_var)"
  end

  test "render regexp with Regex" do
    assert regexp(:name, ~r/Jason/) |> Regexp.render() == "regexp(name, /Jason/)"
  end

  test "render regexp with string" do
    assert regexp(:name, "\d{4}") |> Regexp.render() == "regexp(name, /\d{4}/)"
  end

  test "render anyofterms" do
    assert anyofterms(:beef, "cow bull moo") |> Anyofterms.render() ==
             "anyofterms(beef, \"cow bull moo\")"
  end

  test "render anyoftext" do
    assert anyoftext(:beef, "cow bull moo") |> Anyoftext.render() ==
             "anyoftext(beef, \"cow bull moo\")"
  end

  test "render alloftext" do
    assert alloftext(:beef, "cow bull moo") |> Alloftext.render() ==
             "alloftext(beef, \"cow bull moo\")"
  end

  test "render lt" do
    assert lt(:age, 100) |> Lt.render() == "lt(age, 100)"
  end

  test "render le" do
    assert le(:age, 100) |> Le.render() == "le(age, 100)"
  end

  test "render gt" do
    assert gt(:age, 100) |> Gt.render() == "gt(age, 100)"
  end

  test "render ge" do
    assert ge(:age, 100) |> Ge.render() == "ge(age, 100)"
  end

  test "render sum" do
    assert sum(val(:experience)) |> Sum.render() == "sum(val(experience))"
  end

  test "render avg" do
    assert avg(val(:experience)) |> Avg.render() == "avg(val(experience))"
  end

  test "render min" do
    assert min(val(:experience)) |> Min.render() == "min(val(experience))"
  end

  test "render max" do
    assert max(val(:experience)) |> Max.render() == "max(val(experience))"
  end

  test "render has" do
    assert has(:age) |> Has.render() == "has(age)"
  end

  test "render expand" do
    assert expand(:_uid_) |> render == "expand(_uid_)"
  end

  test "render uid_in" do
    assert uid_in(:foots, "0x123") |> render == "uid_in(foots, 0x123)"
  end
end
