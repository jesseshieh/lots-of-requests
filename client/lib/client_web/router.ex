defmodule ClientWeb.Router do
  use ClientWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ClientWeb do
    pipe_through :api
    get "/", PageController, :index
  end
end
