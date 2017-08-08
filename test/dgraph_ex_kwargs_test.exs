defmodule DgraphEx.KwargsTest do
  use ExUnit.Case
  doctest DgraphEx.Query.Kwargs
  alias DgraphEx.Query.Kwargs
  import DgraphEx

  test "a query call returns a query" do
    assert Kwargs.query([]) == %DgraphEx.Query{}
  end

  test "a simple get func select query renders correctly" do
    q = Kwargs.query [
         get: :person,
        func: eq(:name, "Jason"),
      select: { :name, :age, :height, }
    ]
    assert render(q) == "{ person(func: eq(name, \"Jason\")) { name age height } }"
  end

  test "aliasing with :as works" do
    q = Kwargs.query [
          as: :person,
        func: eq(:name, "Jason"),
      select: { :name, :age, :height, }
    ]
    assert render(q) == "{ person as var(func: eq(name, \"Jason\")) { name age height } }"
  end

  test ":filter works" do
    q = Kwargs.query(get: :person,
                    func: eq(:name, "Jason"),
                  filter: lt(:age, 15),
                  select: { :name, :age, :height, })
    
    assert render(q) == "{ person(func: eq(name, \"Jason\")) @filter(lt(age, 15)) { name age height } }"
  end

  test "directives works" do
    q = Kwargs.query(get: :person,
                    func: eq(:name, "Jason"),
               normalize: true,
                 cascade: true,
            ignorereflex: true,
                  select: { :name, :age, :height, })
    
    assert render(q) == "{ person(func: eq(name, \"Jason\")) @normalize @cascade @ignorereflex { name age height } }"
  end
  test "directives list works" do
    q = Kwargs.query(get: :person,
                    func: eq(:name, "Jason"),
              directives: [:cascade, :ignorereflex],
                  select: { :name, :age, :height, })
    
    assert render(q) == "{ person(func: eq(name, \"Jason\")) @cascade @ignorereflex { name age height } }"
  end
end
