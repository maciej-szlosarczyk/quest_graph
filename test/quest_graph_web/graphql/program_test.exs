defmodule QuestGraphWeb.Graphql.ProgramTest do
  alias QuestGraph.Schema.Cursor
  use QuestGraphWeb.ConnCase, async: true

  setup [:seed_programs, :seed_quests, :seed_resources]

  test "gets a single program and associated quests", %{
    conn: conn,
    first_program: first_program,
    quests: quests
  } do
    query = """
    query($id: ID!, $name: String) {
      program(id: $id) {
        id,
        name,
        quests(first: 100, name: $name) {
          edges {
            node {
              id
              __typename,
            },
          cursor,
          },
          pageInfo{
            startCursor,
            endCursor,
            hasNextPage,
            hasPreviousPage
          }
        }
        }
    }
    """

    conn = make_graphql_query(conn, query, %{"id" => first_program.id})
    assert conn.status == 200

    assert %{"data" => data} = conn.private[:absinthe_response]
    assert %{"program" => program} = data
    assert %{"quests" => returned_quests} = program

    quests =
      quests
      |> Enum.sort_by(& &1.id, :desc)
      |> Enum.filter(&(&1.program_id == first_program.id))

    expected_edges =
      quests
      |> Enum.take(100)
      |> Enum.map(fn quest ->
        %{
          "cursor" => Cursor.encode(quest),
          "node" => %{
            "id" => "#{quest.id}",
            "__typename" => "Quest"
          }
        }
      end)

    start_cursor = quests |> Enum.at(0) |> Cursor.encode()
    end_cursor = quests |> Enum.at(-1) |> Cursor.encode()

    expected_page_info = %{
      "startCursor" => start_cursor,
      "endCursor" => end_cursor,
      "hasNextPage" => false,
      "hasPreviousPage" => false
    }

    assert expected_edges == get_in(returned_quests, ["edges"])
    assert expected_page_info == get_in(returned_quests, ["pageInfo"])
  end

  test "performance characterstics", context do
    %{conn: conn, first_program: first_program} = context

    query = """
    query($id: ID!, $name: String) {
      program(id: $id) {
        id,
        name,
        quests(first: 100, name: $name) {
          edges {
            node {
              id
              __typename,
            },
          cursor,
          },
          pageInfo{
            startCursor,
            endCursor,
            hasNextPage,
            hasPreviousPage
          }
        }
        }
    }
    """

    attach_telemetry_handler(context)

    conn = make_graphql_query(conn, query, %{"id" => first_program.id})
    assert conn.status == 200

    assert_receive {:telemetry_event,
                    %{
                      event: [:quest_graph, :pagination, :apply_relay_pagination, :start]
                    }}

    assert_receive {:telemetry_event,
                    %{
                      event: [:quest_graph, :pagination, :apply_relay_pagination, :stop],
                      measurements: %{duration: duration}
                    }}

    native_second = :erlang.convert_time_unit(10, :millisecond, :native)
    assert duration < native_second
  end

  test "filter and paginate", %{
    conn: conn,
    first_program: first_program,
    quests: quests
  } do
    query = """
    query($id: ID!, $name: String) {
      program(id: $id) {
        id,
        name,
        quests(first: 100, name: $name) {
          edges {
            node {
              id,
              name
              __typename,
            },
          cursor,
          },
          pageInfo{
            startCursor,
            endCursor,
            hasNextPage,
            hasPreviousPage
          }
        }
        }
    }
    """

    conn =
      make_graphql_query(conn, query, %{
        "id" => first_program.id,
        "name" => "HyperMemory program: 100"
      })

    assert conn.status == 200

    assert %{"data" => data} = conn.private[:absinthe_response]
    assert %{"program" => program} = data
    assert %{"quests" => returned_quests} = program

    quests =
      quests
      |> Enum.sort_by(& &1.id, :desc)
      |> Enum.filter(&(&1.program_id == first_program.id))

    expected_edges =
      quests
      |> Enum.take(1)
      |> Enum.map(fn quest ->
        %{
          "cursor" => Cursor.encode(quest),
          "node" => %{
            "id" => "#{quest.id}",
            "__typename" => "Quest",
            "name" => quest.name
          }
        }
      end)

    start_cursor = quests |> Enum.at(0) |> Cursor.encode()

    expected_page_info = %{
      "startCursor" => start_cursor,
      "endCursor" => start_cursor,
      "hasNextPage" => false,
      "hasPreviousPage" => false
    }

    assert expected_edges == get_in(returned_quests, ["edges"])
    assert expected_page_info == get_in(returned_quests, ["pageInfo"])
  end

  test "filter by name", %{conn: conn, first_program: first_program} do
    query = """
    query($id: ID!, $name: String) {
      program(id: $id) {
        id,
        name,
        quests(name: $name) {
          edgesCount,
          edges {
            node {
              id,
              __typename,
              name
            },
          cursor,
          },
          pageInfo{
            startCursor,
            endCursor,
            hasNextPage,
            hasPreviousPage
          }
        }
        }
    }
    """

    conn =
      make_graphql_query(conn, query, %{"id" => first_program.id, "name" => "this does not exist"})

    assert conn.status == 200

    assert %{"data" => data} = conn.private[:absinthe_response]
    assert %{"program" => program} = data
    assert %{"quests" => returned_quests} = program

    expected_edges = []
    expected_edges_count = 0

    expected_page_info = %{
      "startCursor" => nil,
      "endCursor" => nil,
      "hasNextPage" => false,
      "hasPreviousPage" => false
    }

    assert expected_edges_count == get_in(returned_quests, ["edgesCount"])
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

  def attach_telemetry_handler(context) do
    ref = make_ref()
    test_ref = {context.case, context.test, ref}

    events = [
      [:quest_graph, :pagination, :apply_relay_pagination, :start],
      [:quest_graph, :pagination, :apply_relay_pagination, :stop],
      [:quest_graph, :pagination, :apply_relay_pagination, :exception]
    ]

    send_function =
      &Kernel.send(
        self(),
        {:telemetry_event, %{event: &1, measurements: &2, metadata: &3, config: &4}}
      )

    :telemetry.attach_many(test_ref, events, send_function, nil)
    on_exit(fn -> :telemetry.detach(test_ref) end)
  end
end
