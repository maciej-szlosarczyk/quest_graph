defmodule RelayWithoutFussWeb.PageController do
  use RelayWithoutFussWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
