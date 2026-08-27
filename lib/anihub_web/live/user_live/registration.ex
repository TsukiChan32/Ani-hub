defmodule AnihubWeb.UserLive.Registration do
  use AnihubWeb, :live_view

  alias Anihub.Accounts
  alias Anihub.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl px-3 py-5 sm:px-4">
        <%!-- Auth header --%>
        <div class="mb-5 flex items-center justify-between border-b border-[var(--border)] pb-3">
          <.link
            navigate={~p"/"}
            class="flex items-center gap-2 text-[var(--text)]"
          >
            <span class="border border-[var(--button-border)] bg-[var(--accent)] px-2 py-1 text-sm font-bold text-white">
              A
            </span>

            <span class="text-lg font-bold">
              Anihub
            </span>
          </.link>

          <button
            id="theme-toggle"
            type="button"
            aria-label="Toggle theme"
            class="border border-[var(--border)] bg-[var(--surface)] px-2 py-1 text-sm text-[var(--text-muted)] hover:bg-[var(--surface-hover)]"
          >
            <span class="theme-icon-dark">◐</span>
            <span class="theme-icon-light hidden">◑</span>
          </button>
        </div>

        <%!-- Breadcrumb --%>
        <div class="mb-3 text-xs text-[var(--text-muted)]">
          <.link navigate={~p"/"} class="text-[var(--accent)] hover:underline">
            Home
          </.link>

          <span class="mx-1">»</span>

          <span class="text-[var(--text)]">
            Register
          </span>
        </div>

        <%!-- Registration panel --%>
        <section class="mx-auto max-w-xl border border-[var(--border)] bg-[var(--surface)]">
          <div class="old-panel-header px-3 py-2">
            <h1 class="text-sm font-bold uppercase tracking-wide text-[var(--text)]">
              Create account
            </h1>
          </div>

          <div class="p-4 sm:p-5">
            <p class="mb-4 text-sm text-[var(--text-muted)]">
              Already registered?
              <.link
                navigate={~p"/users/log-in"}
                class="font-semibold text-[var(--accent)] hover:underline"
              >
                Log in »
              </.link>
            </p>

            <.form
              for={@form}
              id="registration_form"
              phx-submit="save"
              phx-change="validate"
            >
              <div class="grid gap-2 sm:grid-cols-[110px_minmax(0,1fr)] sm:items-start">
                <label
                  for={@form[:email].id}
                  class="pt-1.5 text-sm font-semibold text-[var(--text)]"
                >
                  Email
                </label>

                <div>
                  <input
                    id={@form[:email].id}
                    name={@form[:email].name}
                    value={@form[:email].value}
                    type="email"
                    autocomplete="username"
                    spellcheck="false"
                    required
                    phx-mounted={JS.focus()}
                    placeholder="you@example.com"
                    class="w-full border border-[var(--border)] bg-[var(--bg)] px-2 py-1.5 text-sm text-[var(--text)] outline-none placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                  />

                  <%= for error <- @form[:email].errors do %>
                    <p class="mt-1 text-xs text-rose-500">
                      {translate_error(error)}
                    </p>
                  <% end %>
                </div>
              </div>

              <div class="mt-3 sm:pl-[118px]">
                <button
                  type="submit"
                  phx-disable-with="Creating account..."
                  class="old-button"
                >
                  Create account →
                </button>
              </div>
            </.form>

            <div class="mt-4 border-t border-[var(--border)] pt-3 text-xs leading-5 text-[var(--text-muted)]">
              Registration is passwordless. We'll email you a secure link to confirm your account and sign in.
            </div>
          </div>

          <div class="border-t border-[var(--border)] bg-[var(--surface-hover)] px-3 py-2 text-center text-xs text-[var(--text-muted)]">
            AniHub tracks your anime library and release schedule.
            It does not host or stream anime.
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: AnihubWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_email(%User{}, %{}, validate_unique: false)

    {:ok, assign_form(socket, changeset), temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}")
          )

        {:noreply,
         socket
         |> put_flash(
           :info,
           "An email was sent to #{user.email}, please access it to confirm your account."
         )
         |> push_navigate(to: ~p"/users/log-in")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      Accounts.change_user_email(
        %User{},
        user_params,
        validate_unique: false
      )

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
