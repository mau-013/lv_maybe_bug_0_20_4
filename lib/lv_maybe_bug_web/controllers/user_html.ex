defmodule LvMaybeBugWeb.UserHtml do
  use LvMaybeBugWeb, :html

  def show(assigns) do
    ~H"""
    <p>Name: <%= Map.get(@user, "name") %></p>
    <p>Age: <%= Map.get(@user, "age") %></p>
    <p>internal_value: <%= Map.get(@user, "internal_value") %></p>
    """
  end

end
