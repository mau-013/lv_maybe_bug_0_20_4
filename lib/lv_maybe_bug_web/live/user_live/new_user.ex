defmodule LvMaybeBugWeb.NewUserLive do
  use LvMaybeBugWeb, :live_view
  # use LvMaybeBugWeb, :live_component

  alias LvMaybeBug.Accounts
  alias LvMaybeBug.Accounts.User
  alias LvMaybeBugWeb.UserLive.FormComponent

  # @impl true
  def render(assigns) do
    ~H"""
    <.header>
      New User
      <:subtitle>Use this form to manage user records in your database.</:subtitle>
    </.header>
    <.live_component
      module={FormComponent}
      id="new-user"
      name={@form[:name].value}
      age={@form[:age].value}
    />
    <div>
      <.simple_form
        for={@form}
        id="parent-form"
        phx-change="validate"
        phx-submit="save"
        phx-trigger-action={@trigger_submit}
        action={~p"/?_action=insert"}
        method="post"
      >
        <input type="hidden" name={@form[:name].name} value={@form[:name].value} />
        <input type="hidden" name={@form[:age].name} value={@form[:age].value} />
        <input type="hidden" name={@form[:internal_value].name} value={@form[:internal_value].value} />
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user(%User{}, %{})
    {:ok, socket |> assign(trigger_submit: false) |> assign_form(changeset)}
  end

  # @impl true
  # def update(%{user: user} = assigns, socket) do
  #   changeset = Accounts.change_user(user)

  #   {:ok,
  #    socket
  #    |> assign(assigns)
  #    |> assign_form(changeset)}
  # end

  # @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  # defp save_user(socket, :edit, user_params) do
  #   case Accounts.update_user(socket.assigns.user, user_params) do
  #     {:ok, user} ->
  #       notify_parent({:saved, user})

  #       {:noreply,
  #        socket
  #        |> put_flash(:info, "User updated successfully")
  #        |> push_patch(to: socket.assigns.patch)}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign_form(socket, changeset)}
  #   end
  # end

  defp save_user(socket, :new, user_params) do
    IO.puts("**** SAVE PARAMS")
    final_params = Map.put(user_params, "internal_value", "OK")
    IO.inspect(final_params)
    changeset = User.changeset(%User{}, final_params)
    case changeset.valid? do
      true ->
        {:noreply,
         socket
         |> assign_form(changeset)
         |> assign(trigger_submit: true)}

      false ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid")}
    end
    # case Accounts.create_user(user_params) do
    #   {:ok, user} ->
    #     notify_parent({:saved, user})

    #     {:noreply,
    #      socket
    #      |> put_flash(:info, "User created successfully")
    #      |> push_patch(to: socket.assigns.patch)}

    #   {:error, %Ecto.Changeset{} = changeset} ->
    #     {:noreply, assign_form(socket, changeset)}
    # end
  end

  def handle_info({:create_user, {:valid, user_params}}, socket) do
    save_user(socket, :new, user_params)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  # defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
