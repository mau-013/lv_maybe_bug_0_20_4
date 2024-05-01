defmodule LvMaybeBugWeb.UserLive.FormComponent do
  use LvMaybeBugWeb, :live_component

  alias LvMaybeBug.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        for={@form}
        id="component-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:age]} type="number" label="Age" />
        <:actions>
          <.button phx-disable-with="Saving...">Save User</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    name = assigns.name
    age = assigns.age
    changeset = User.component_changeset(%User{}, %{name: name, age: age})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      User.component_changeset(%User{}, user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, :new, user_params)
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
    changeset = User.component_changeset(%User{}, user_params)
    case changeset.valid? do
      true ->
        notify_parent({:valid, user_params})

        {:noreply, socket}

      false ->
        {:noreply, assign_form(socket, changeset |> Map.put(:action, :validate))}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    IO.inspect(to_form(changeset))
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {:create_user, msg})
end
