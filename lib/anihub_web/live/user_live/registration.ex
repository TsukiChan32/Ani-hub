defmodule AnihubWeb.UserLive.Registration do
  use AnihubWeb, :live_view

  alias Anihub.Accounts
  alias Anihub.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen px-4 py-6 sm:px-6 sm:py-8">
        <div class="mx-auto max-w-6xl">
          <%!-- Auth navigation --%>
          <nav class="mb-8 flex items-center justify-between sm:mb-10">
            <.link
              navigate={~p"/"}
              class="group flex items-center gap-3"
            >
              <div class="flex size-10 items-center justify-center rounded-xl bg-[var(--accent)] font-bold text-white transition-colors group-hover:bg-[var(--accent-hover)]">
                A
              </div>

              <span class="text-xl font-bold tracking-tight text-[var(--text)]">
                Anihub
              </span>
            </.link>

            <button
              id="theme-toggle"
              type="button"
              aria-label="Toggle theme"
              class="flex size-10 cursor-pointer items-center justify-center rounded-xl text-[var(--text-muted)] transition-colors hover:bg-[var(--surface-hover)] hover:text-[var(--text)]"
            >
              <span class="theme-icon-dark">
                <.icon name="hero-moon" class="size-5" />
              </span>

              <span class="theme-icon-light hidden">
                <.icon name="hero-sun" class="size-5" />
              </span>
            </button>
          </nav>

          <%!-- Main auth area --%>
          <div class="grid min-h-[calc(100vh-150px)] items-center gap-12 lg:grid-cols-[minmax(0,1fr)_460px] lg:gap-20">
            <%!-- Desktop intro --%>
            <section class="hidden lg:block">
              <div class="max-w-2xl">
                <p class="text-sm font-semibold uppercase tracking-wider text-[var(--accent)]">
                  Start tracking
                </p>

                <h1 class="mt-3 text-5xl font-bold tracking-tight text-[var(--text)] xl:text-6xl">
                  Build your anime library.
                </h1>

                <p class="mt-5 max-w-xl text-lg leading-8 text-[var(--text-muted)]">
                  Save what you're watching, track episode progress, rate titles and keep up with releases.
                </p>

                <div class="mt-10 grid max-w-xl gap-4 sm:grid-cols-2">
                  <div class="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5">
                    <div class="flex size-10 items-center justify-center rounded-xl bg-blue-500/15 text-blue-500">
                      <.icon name="hero-bookmark" class="size-5" />
                    </div>

                    <p class="mt-4 font-semibold text-[var(--text)]">
                      Your own library
                    </p>

                    <p class="mt-1 text-sm leading-6 text-[var(--text-muted)]">
                      Organize anime by watching status and progress.
                    </p>
                  </div>

                  <div class="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5">
                    <div class="flex size-10 items-center justify-center rounded-xl bg-violet-500/15 text-violet-500">
                      <.icon name="hero-star" class="size-5" />
                    </div>

                    <p class="mt-4 font-semibold text-[var(--text)]">
                      Rate what you watch
                    </p>

                    <p class="mt-1 text-sm leading-6 text-[var(--text-muted)]">
                      Keep your own scores alongside AniList ratings.
                    </p>
                  </div>
                </div>
              </div>
            </section>

            <%!-- Registration card --%>
            <section class="mx-auto w-full max-w-md lg:mx-0">
              <div class="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-7">
                <div>
                  <p class="text-sm font-semibold uppercase tracking-wider text-[var(--accent)] lg:hidden">
                    Start tracking
                  </p>

                  <h2 class="mt-1 text-3xl font-bold tracking-tight text-[var(--text)]">
                    Create account
                  </h2>

                  <p class="mt-2 text-sm leading-6 text-[var(--text-muted)]">
                    Already registered?
                    <.link
                      navigate={~p"/users/log-in"}
                      class="font-semibold text-[var(--accent)] transition-colors hover:text-[var(--accent-hover)]"
                    >
                      Log in
                    </.link>
                  </p>
                </div>

                <.form
                  for={@form}
                  id="registration_form"
                  phx-submit="save"
                  phx-change="validate"
                  class="mt-7"
                >
                  <label
                    for={@form[:email].id}
                    class="mb-2 block text-sm font-medium text-[var(--text)]"
                  >
                    Email
                  </label>

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
                    class="w-full rounded-xl border border-[var(--border)] bg-[var(--bg)] px-4 py-3 text-[var(--text)] outline-none transition-colors placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                  />

                  <%= for error <- @form[:email].errors do %>
                    <p class="mt-2 text-sm text-rose-500">
                      {translate_error(error)}
                    </p>
                  <% end %>

                  <button
                    type="submit"
                    phx-disable-with="Creating account..."
                    class="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[var(--accent)] px-4 py-3 font-semibold text-white transition-colors hover:bg-[var(--accent-hover)] disabled:cursor-wait disabled:opacity-70"
                  >
                    Create account <.icon name="hero-arrow-right" class="size-4" />
                  </button>
                </.form>

                <div class="mt-6 rounded-2xl border border-[var(--border)] bg-[var(--bg)] p-4">
                  <div class="flex gap-3">
                    <.icon
                      name="hero-envelope"
                      class="mt-0.5 size-5 shrink-0 text-[var(--accent)]"
                    />

                    <div>
                      <p class="text-sm font-medium text-[var(--text)]">
                        Passwordless registration
                      </p>

                      <p class="mt-1 text-xs leading-5 text-[var(--text-muted)]">
                        We'll email you a secure link to confirm your account and sign in.
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <p class="mt-4 text-center text-xs leading-5 text-[var(--text-muted)]">
                AniHub tracks your anime library and release schedule.
                It does not host or stream anime.
              </p>
            </section>
          </div>
        </div>
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
