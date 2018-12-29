defmodule ServerWeb.Router do
  use ServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ServerWeb do
    get "/", PageController, :index
  end
end
