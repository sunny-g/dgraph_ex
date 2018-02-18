defmodule PersistanceDemo do
  use ExUnit.Case

  import DgraphEx
  alias DgraphEx.Repo

  @commit_now true

  # import DgraphEx.Field
  # alias DgraphEx.Alter

  def new_resource() do

    result = set()
    |> field(:resource, :title, "Hello World", :string)
    |> field(:resource, :blob, :blob1, :uid)
    |> field(:blob1, :html, "<h1>Hello World</h1><p>Lorem ipsum</p>", :string)

    render(result) |> IO.puts

    result = result
    |> Repo.mutate(@commit_now)

  end

  def alter_predicates() do

    result = alter()
    |> field(:title, :string, index: [:term])
    |> field(:html, :string, [])
    |> field(:blob, :uid, reverse: true)

    render(result) |> IO.puts

    result = result
    |> Repo.alter()

  end

  def cleanup() do

    result = delete()
    |> field("*", :blob, "*")
    |> field("*", :title, "*")
    |> field("*", :html, "*")

    render(result) |> IO.puts

    result = result
    |> Repo.mutate(@commit_now)

  end

  def get_resource(id) do

    result = query()
    |> func(:get, uid(id))
    |> select({
      :uid,
      :title,
      blob: select({:html})
    })

    render(result) |> IO.puts

    result = result
    |> Repo.query

  end

  def all_resources() do

    result = query()
    |> func(:all, eq(:title, "Hello World"))
    |> select({
      :uid,
      :title,
      blob: select({:html})
    })

    render(result) |> IO.puts

    result = result
    |> Repo.query
  end


  def delete_resource(id) do

    result = delete()
    |> field(uid(id), "*", "*")

    render(result) |> IO.puts

    result = result
    |> Repo.mutate(@commit_now)

  end

  def delete_all([%{"uid" => id}|resources]) do
    delete_resource(id)

    delete_all(resources)
  end

  def delete_all([]), do: nil

  test "set new resource" do

    {:ok, %{uids: %{"resource" => resource_id}}} = new_resource()

    alter_predicates()

    {:ok, %{data: %{"get" => resource}}} = get_resource(resource_id)

    assert [%{"blob" => [%{"html" => "<h1>Hello World</h1><p>Lorem ipsum</p>"}], "title" => "Hello World", "uid" => _}] = resource

    {:ok, %{data: %{"all" => resources}}} = all_resources()

    assert [%{"blob" => [%{"html" => "<h1>Hello World</h1><p>Lorem ipsum</p>"}], "title" => "Hello World", "uid" => _}] = resources

    delete_all(resources)

    {:ok, %{data: %{"all" => resources}}} = all_resources()

    assert resources == []

    cleanup()

  end

end
