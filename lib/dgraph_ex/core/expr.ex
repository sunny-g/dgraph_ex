defmodule DgraphEx.Core.Expr do
  @moduledoc false

  alias DgraphEx.Core.Expr.{
    # indices
    Allofterms,
    Anyofterms,
    Alloftext,
    Anyoftext,
    Eq,
    Regexp,

    # Neq indices
    Neq,
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

    # geo
    Near,
    Within,
    Contains,
    Intersects,

    # simples
    Val,
    Count,
    Uid,
    Has,
    Expand,
    UidIn
  }

  defmacro __using__(_) do
    quote do
      # indexes
      use Eq
      use Allofterms
      use Anyofterms
      use Alloftext
      use Anyoftext
      use Regexp

      # Neq indexes
      require Neq
      Neq.define_funcs(Lt, :lt)
      Neq.define_funcs(Le, :le)
      Neq.define_funcs(Gt, :gt)
      Neq.define_funcs(Ge, :ge)

      # aggs
      require Agg
      Agg.define_funcs(Sum, :sum)
      Agg.define_funcs(Avg, :avg)
      Agg.define_funcs(Min, :min)
      Agg.define_funcs(Max, :max)

      # geo
      use Near
      use Within
      use Contains
      use Intersects

      # simples
      use Val
      use Count
      use Uid
      use Has
      use Expand
      use UidIn
    end
  end
end
