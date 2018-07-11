defmodule DgraphEx.Repo do
  alias DgraphEx.{
    Alter,
    Client,
    Delete,
    Field,
    Kwargs,
    Set,
    Query,
    Vertex,
  }

  @alter_path "/alter"
  @query_path "/path"
  @mutate_path "/mutate"

  def alter([%Field{} | _] = fields), do: Client.send(data: Alter.new(fields))
  def alter(%Alter{} = alter), do: Client.send(data: alter, path: @alter_path)
  def alter(module) when is_atom(module) do
    if !Vertex.is_model?(module) do
      raise %ArgumentError{
        message: "DgraphEx.Repo.alter/1 only responds to Vertex models. #{module} does not use DgraphEx.Vertex"
      }
    end
    data =
      module.__vertex__(:fields)
      |> Alter.new()
    Client.send(data: data)
  end

  def mutate(_, commit_now \\ false)
  def mutate(%Set{} = set, commit_now),       do: do_mutate(set, commit_now)
  def mutate(%Delete{} = delete, commit_now), do: do_mutate(delete, commit_now)

  def query(%Query{} = query), do: Client.send(data: query, path: @query_path)
  def query(kwargs) when is_list(kwargs) do
    Client.send(data: Kwargs.parse(kwargs), path: @query_path)
  end

  defp do_mutate(data, false), do: Client.send(data: data, path: @mutate_path)
  defp do_mutate(data, true) do
    Client.send([
      data: data,
      path: @mutate_path,
      headers: [{"X-Dgraph-CommitNow", true}],
    ])
  end
end
