use Mix.Config

config :dgraph_ex,
  adapter: DgraphEx.Client.HTTP,
  endpoint: "http://localhost:8080"
