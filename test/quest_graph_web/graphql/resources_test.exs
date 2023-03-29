defmodule QuestGraphWeb.Graphql.ResourcesTest do
  alias QuestGraph.Schema.Cursor
  use QuestGraphWeb.ConnCase, async: true

  setup [:seed_programs, :seed_quests, :seed_resources]

  test "gets resources with pagination args {first: 10}", %{conn: conn, resources: resources} do
    query = """
    query($first: Int!) {
      resources(first: $first) {
        edges {
          cursor,
          node {
            id
            quest{ id, name }
          }
        },
        edgesCount,
        pageInfo {
          endCursor
          startCursor
          hasNextPage,
          hasPreviousPage
        }
      }
    }
    """

    conn = make_graphql_query(conn, query, %{"first" => 10})
    assert conn.status == 200

    assert %{"data" => data} = conn.private[:absinthe_response]
    assert %{"resources" => returned_resources} = data
    assert %{"edgesCount" => 600} = returned_resources

    expected_edges =
      resources
      |> Enum.sort_by(& &1.id, :desc)
      |> Enum.take(10)
      |> QuestGraph.Repo.preload(:quest)
      |> Enum.map(fn resource ->
        %{
          "cursor" => Cursor.encode(resource),
          "node" => %{
            "id" => "#{resource.id}",
            "quest" => %{
              "id" => "#{resource.quest.id}",
              "name" => resource.quest.name
            }
          }
        }
      end)

    start_cursor = resources |> Enum.at(-1) |> Cursor.encode()
    end_cursor = resources |> Enum.at(-10) |> Cursor.encode()

    expected_page_info = %{
      "startCursor" => start_cursor,
      "endCursor" => end_cursor,
      "hasNextPage" => true,
      "hasPreviousPage" => false
    }

    assert expected_edges == get_in(returned_resources, ["edges"])
    assert expected_page_info == get_in(returned_resources, ["pageInfo"])
  end

  test "gets all resources with no pagination", %{conn: conn, resources: resources} do
    query = """
    query {
      resources {
        edges {
          cursor,
          node {
            id
            quest{ id, name }
          }
        },
        edgesCount,
        pageInfo {
          endCursor
          startCursor
          hasNextPage,
          hasPreviousPage
        }
      }
    }
    """

    conn = make_graphql_query(conn, query)
    assert conn.status == 200

    assert %{"data" => data} = conn.private[:absinthe_response]
    assert %{"resources" => returned_resources} = data
    assert %{"edgesCount" => 600} = returned_resources

    expected_edges =
      resources
      |> Enum.sort_by(& &1.id, :desc)
      |> QuestGraph.Repo.preload(:quest)
      |> Enum.map(fn resource ->
        %{
          "cursor" => Cursor.encode(resource),
          "node" => %{
            "id" => "#{resource.id}",
            "quest" => %{
              "id" => "#{resource.quest.id}",
              "name" => resource.quest.name
            }
          }
        }
      end)

    start_cursor = resources |> Enum.at(-1) |> Cursor.encode()
    end_cursor = resources |> Enum.at(0) |> Cursor.encode()

    expected_page_info = %{
      "startCursor" => start_cursor,
      "endCursor" => end_cursor,
      "hasNextPage" => false,
      "hasPreviousPage" => false
    }

    assert expected_edges == get_in(returned_resources, ["edges"])
    assert expected_page_info == get_in(returned_resources, ["pageInfo"])
  end

  def make_graphql_query(conn, query), do: make_graphql_query(conn, query, %{})

  def make_graphql_query(conn, query, variables) do
    params = %{"query" => query, "variables" => variables} |> Jason.encode!()

    conn =
      conn
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> post("/graphql", params)

    absinthe_response = Jason.decode!(conn.resp_body)
    Plug.Conn.put_private(conn, :absinthe_response, absinthe_response)
  end
end
