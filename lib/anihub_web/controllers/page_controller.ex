defmodule AnihubWeb.PageController do
  use AnihubWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
