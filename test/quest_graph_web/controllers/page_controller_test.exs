defmodule QuestGraphWeb.PageControllerTest do
  use QuestGraphWeb.ConnCase

  setup [:seed_programs, :seed_quests, :seed_resources]

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
