defmodule ServerWeb.PageController do
  use ServerWeb, :controller

  def index(conn, _params) do
    json conn, %{}
  end
end
