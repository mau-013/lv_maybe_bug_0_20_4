defmodule LvMaybeBugWeb.UserController do
  use LvMaybeBugWeb, :controller

  import Plug.Conn

  def create(conn, params) do
    # Simply add the params to the conn and forward them for rendering
    IO.puts("***** POST RECEIVED PARAMS")
    IO.inspect(params["user"])
    redirect(conn |> put_session(:user, params["user"]), to: ~p"/user")
  end

  def show(conn, _params) do
    user = get_session(conn, "user")
    IO.puts("*** GET")
    IO.inspect(user)
    conn
    |> put_view(LvMaybeBugWeb.UserHtml)
    |> render(:show, user: user)
  end
end
