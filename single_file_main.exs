# created this single file as part of the bug report process
# in the end there was no need to submit the report, because
# testing with the latest main branch showed the problem was solved

# keeping this repo and single file app as example

# run with `elixir main.exs`

Application.put_env(:sample, LvMaybeBug.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  server: true,
  live_view: [signing_salt: "aaaaaaaa"],
  secret_key_base: String.duplicate("a", 64)
)

Mix.install([
  {:plug_cowboy, "~> 2.5"},
  {:jason, "~> 1.0"},
  {:phoenix, "~> 1.7"},
  # please test your issue using the latest version of LV from GitHub!
  # {:phoenix_live_view, "0.20.3"},  # WORKS
  # {:phoenix_live_view, "0.20.4"},  # DOESN'T WORK
  {:phoenix_live_view, github: "phoenixframework/phoenix_live_view", branch: "main", override: true},
  {:phoenix_ecto, "~> 4.4"},
])

# build the LiveView JavaScript assets (this needs mix and npm available in your path!)
path = Phoenix.LiveView.__info__(:compile)[:source] |> Path.dirname() |> Path.join("../")
System.cmd("mix", ["deps.get"], cd: path, into: IO.binstream())
System.cmd("npm", ["install"], cd: Path.join(path, "./assets"), into: IO.binstream())
System.cmd("mix", ["assets.build"], cd: path, into: IO.binstream())

defmodule LvMaybeBug.ErrorView do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule LvMaybeBug.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :age, :integer
    field :internal_value, :string

    timestamps()
  end

  @doc false
  def component_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :age])
    |> validate_required([:name, :age])
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :age, :internal_value])
    |> validate_required([:name, :age, :internal_value])
  end
end


defmodule LvMaybeBugWeb.CoreComponents do
  # alias ElixirSense.Plugins.Phoenix
  use Phoenix.Component

  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(hidden number text)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :errors, :list, default: []

  attr :rest, :global,
  include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
              multiple pattern placeholder readonly required rows size step)

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, field.errors)
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-zinc-300 phx-no-feedback:focus:border-zinc-400",
          @errors == [] && "border-zinc-300 focus:border-zinc-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end


  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600 phx-no-feedback:hidden">
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold leading-8 text-zinc-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end
end

defmodule LvMaybeBugWeb.NewUserLive do
  use Phoenix.LiveView, layout: {__MODULE__, :live}

  import LvMaybeBugWeb.CoreComponents

  alias LvMaybeBug.User
  alias LvMaybeBugWeb.FormComponent

  def render("live.html", assigns) do
    ~H"""
    <script src="/assets/phoenix/phoenix.js"></script>
    <script src="/assets/phoenix_live_view/phoenix_live_view.js"></script>
    <%!-- uncomment to use enable tailwind --%>
    <%!-- <script src="https://cdn.tailwindcss.com"></script> --%>
    <script>
      let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket)
      liveSocket.connect()
    </script>
    <style>
      * { font-size: 1.1em; }
    </style>
    <%= @inner_content %>
    """
  end

  # @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Buggy example (no DB)
    </.header>
    <.live_component
      module={FormComponent}
      id="new-user"
      name={@form[:name].value}
      age={@form[:age].value}
    />
    <div>
      <.form
        for={@form}
        id="parent-form"
        phx-change="validate"
        phx-submit="save"
        phx-trigger-action={@trigger_submit}
        action={"/"}
        method="post"
      >
        <input type="hidden" name={@form[:name].name} value={@form[:name].value} />
        <input type="hidden" name={@form[:age].name} value={@form[:age].value} />
        <input type="hidden" name={@form[:internal_value].name} value={@form[:internal_value].value} />
      </.form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = User.changeset(%User{}, %{})
    {:ok, socket |> assign(trigger_submit: false) |> assign_form(changeset)}
  end

  # @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = User.changeset(%User{}, user_params)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :new, user_params) do
    IO.puts("**** SAVE PARAMS")
    final_params = Map.put(user_params, "internal_value", "OK")
    IO.inspect(final_params)
    changeset = User.changeset(%User{}, final_params)
    case changeset.valid? do
      true ->
        socket = socket |> assign_form(changeset)
        IO.inspect(socket.assigns)
        {:noreply,
         socket
        #  |> assign_form(changeset)
         |> assign(trigger_submit: true)}

      false ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid")}
    end
  end

  def handle_info({:create_user, {:valid, user_params}}, socket) do
    save_user(socket, :new, user_params)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end

defmodule LvMaybeBugWeb.FormComponent do
  use Phoenix.LiveComponent

  import LvMaybeBugWeb.CoreComponents

  alias LvMaybeBug.User

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
      # |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, :new, user_params)
  end

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
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {:create_user, msg})
end

defmodule LvMaybeBugWeb.UserController do
  use Phoenix.Controller,
  formats: [:html, :json],
  layouts: []

  import Plug.Conn

  def create(conn, params) do
    # Simply add the params to the conn and forward them for rendering
    IO.puts("***** POST RECEIVED PARAMS")
    IO.inspect(params)
    # IO.inspect(
    #   Enum.reduce(
    #     params["user"],
    #     "", fn {key, value}, acc ->
    #       acc <> key <> "=" <> value
    #     end))
    # redirect_url = "/user?#{param_string}"
    redirect(
      conn |> fetch_session() |> put_session(:user, params["user"]),
      to: "/user")
  end

  def show(conn, _params) do
    conn = fetch_session(conn)
    user = get_session(conn, "user")
    IO.puts("*** GET")
    IO.inspect(user)
    conn
    |> put_view(LvMaybeBugWeb.UserHtml)
    |> render(:show, user: user)
  end
end

defmodule LvMaybeBugWeb.UserHtml do
  use Phoenix.Component

  # Import convenience functions from controllers
  import Phoenix.Controller,
    only: [get_csrf_token: 0, view_module: 1, view_template: 1]
  import Phoenix.HTML

  def show(assigns) do
    ~H"""
    <p>Name: <%= Map.get(@user, "name", "") %></p>
    <p>Age: <%= Map.get(@user, "age", "") %></p>
    <p>internal_value: <%= Map.get(@user, "internal_value", "") %></p>
    """
  end

end

defmodule LvMaybeBug.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/", LvMaybeBugWeb do
    pipe_through(:browser)

    # live("/", HomeLive, :index)
    live "/", NewUserLive, :new
    post "/", UserController, :create
    get "/user", UserController, :show
  end
end

defmodule LvMaybeBug.Endpoint do
  use Phoenix.Endpoint, otp_app: :sample
  socket("/live", Phoenix.LiveView.Socket)

  plug Plug.Static, from: {:phoenix, "priv/static"}, at: "/assets/phoenix"
  plug Plug.Static, from: {:phoenix_live_view, "priv/static"}, at: "/assets/phoenix_live_view"

  plug Plug.Session, [
    store: :cookie,
    key: "_lv_maybe_bug_key",
    signing_salt: "2spRSpj7",
    same_site: "Lax"
  ]
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug(LvMaybeBug.Router)
end

{:ok, _} = Supervisor.start_link([LvMaybeBug.Endpoint], strategy: :one_for_one)
Process.sleep(:infinity)
