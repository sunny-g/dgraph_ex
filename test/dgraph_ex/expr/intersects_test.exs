defmodule DgraphEx.Expr.IntersectsTest do
  use ExUnit.Case, async: true
  doctest DgraphEx.Expr.Intersects
  import TestHelpers

  import DgraphEx

  test "intersects renders correctly" do
    geo_json = [[
      [-122.47266769409178, 37.769018558337926 ],
      [ -122.47266769409178, 37.773699921075135 ],
      [ -122.4651575088501, 37.773699921075135 ],
      [ -122.4651575088501, 37.769018558337926 ],
      [ -122.47266769409178, 37.769018558337926],
    ]]

    geo_string = "[[[-122.47266769409178,37.769018558337926],[-122.47266769409178,37.773699921075135],[-122.4651575088501,37.773699921075135],[-122.4651575088501,37.769018558337926],[-122.47266769409178,37.769018558337926]]]"
    assert render(intersects(:loc, geo_json)) == clean_format("""
      intersects(loc, #{geo_string})
    """)
  end
end
