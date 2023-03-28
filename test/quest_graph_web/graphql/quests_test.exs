defmodule QuestGraphWeb.Graphql.QuestsTest do
  alias QuestGraph.Schema.Cursor
  use QuestGraphWeb.ConnCase, async: true

  setup [:seed_programs, :seed_quests, :seed_resources]

  test "gets all quests with no pagination", %{conn: conn, quests: quests} do
    query = """
    query {
      quests {
        edges {
          cursor,
          node {
            id
            program{ id, name }
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
    assert %{"quests" => returned_quests} = data
    assert %{"edgesCount" => 1000} = returned_quests

    expected_edges =
      quests
      |> Enum.sort_by(& &1.id, :desc)
      |> QuestGraph.Repo.preload(:program)
      |> Enum.map(fn quest ->
        %{
          "cursor" => Cursor.encode(quest),
          "node" => %{
            "id" => "#{quest.id}",
            "program" => %{
              "id" => "#{quest.program_id}",
              "name" => quest.program.name
            }
          }
        }
      end)

    start_cursor = quests |> Enum.at(-1) |> Cursor.encode()
    end_cursor = quests |> Enum.at(0) |> Cursor.encode()

    expected_page_info = %{
      "startCursor" => start_cursor,
      "endCursor" => end_cursor,
      "hasNextPage" => false,
      "hasPreviousPage" => false
    }

    assert expected_edges == get_in(returned_quests, ["edges"])
    assert expected_page_info == get_in(returned_quests, ["pageInfo"])
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
