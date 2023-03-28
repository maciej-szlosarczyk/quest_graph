defmodule QuestGraphWeb.Graphql.ProgramsTest do
  alias QuestGraph.Schema.Cursor
  use QuestGraphWeb.ConnCase, async: true

  setup [:seed_programs, :seed_quests, :seed_resources]

  test "gets all programs with no pagination", %{
    conn: conn,
    first_program: first_program,
    second_program: second_program
  } do
    query = """
    query {
      programs {
        edges {
          cursor,
          node {
            id
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
    assert %{"programs" => programs} = data
    assert %{"edgesCount" => 2} = programs

    expected_edges = [
      %{"cursor" => Cursor.encode(second_program), "node" => %{"id" => "#{second_program.id}"}},
      %{"cursor" => Cursor.encode(first_program), "node" => %{"id" => "#{first_program.id}"}}
    ]

    expected_page_info = %{
      "startCursor" => Cursor.encode(second_program),
      "endCursor" => Cursor.encode(first_program),
      "hasNextPage" => false,
      "hasPreviousPage" => false
    }

    assert expected_edges == get_in(programs, ["edges"])
    assert expected_page_info == get_in(programs, ["pageInfo"])
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
