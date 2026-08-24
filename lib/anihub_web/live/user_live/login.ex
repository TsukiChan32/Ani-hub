defmodule AnihubWeb.UserLive.Login do
  use AnihubWeb, :live_view

  alias Anihub.Accounts

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
                  Welcome back
                </p>

                <h1 class="mt-3 text-5xl font-bold tracking-tight text-[var(--text)] xl:text-6xl">
                  Pick up where you left off.
                </h1>

                <p class="mt-5 max-w-xl text-lg leading-8 text-[var(--text-muted)]">
                  Keep your anime library, progress, ratings and release calendar in one place.
                </p>

                <div class="mt-10 grid max-w-xl gap-4 sm:grid-cols-2">
                  <div class="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5">
                    <div class="flex size-10 items-center justify-center rounded-xl bg-blue-500/15 text-blue-500">
                      <.icon name="hero-bookmark" class="size-5" />
                    </div>

                    <p class="mt-4 font-semibold text-[var(--text)]">
                      Track your library
                    </p>

                    <p class="mt-1 text-sm leading-6 text-[var(--text-muted)]">
                      Watching, planning, completed and dropped.
                    </p>
                  </div>

                  <div class="rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5">
                    <div class="flex size-10 items-center justify-center rounded-xl bg-violet-500/15 text-violet-500">
                      <.icon name="hero-calendar-days" class="size-5" />
                    </div>

                    <p class="mt-4 font-semibold text-[var(--text)]">
                      Follow releases
                    </p>

                    <p class="mt-1 text-sm leading-6 text-[var(--text-muted)]">
                      See upcoming episodes in your local time.
                    </p>
                  </div>
                </div>
              </div>
            </section>

            <%!-- Login card --%>
            <section class="mx-auto w-full max-w-md lg:mx-0">
              <div class="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-7">
                <div>
                  <p class="text-sm font-semibold uppercase tracking-wider text-[var(--accent)] lg:hidden">
                    Welcome back
                  </p>

                  <h2 class="mt-1 text-3xl font-bold tracking-tight text-[var(--text)]">
                    Log in
                  </h2>

                  <%= if @current_scope do %>
                    <p class="mt-2 text-sm leading-6 text-[var(--text-muted)]">
                      Reauthenticate to continue with this sensitive action.
                    </p>
                  <% else %>
                    <p class="mt-2 text-sm leading-6 text-[var(--text-muted)]">
                      Don't have an account?
                      <.link
                        navigate={~p"/users/register"}
                        class="font-semibold text-[var(--accent)] transition-colors hover:text-[var(--accent-hover)]"
                      >
                        Sign up
                      </.link>
                    </p>
                  <% end %>
                </div>

                <%!-- Dev mailbox notice --%>
                <div
                  :if={local_mail_adapter?()}
                  class="mt-5 flex gap-3 rounded-2xl border border-blue-500/20 bg-blue-500/10 px-4 py-3"
                >
                  <.icon
                    name="hero-information-circle"
                    class="mt-0.5 size-4 shrink-0 text-blue-500"
                  />

                  <div class="text-xs leading-5 text-[var(--text-muted)]">
                    <p class="font-medium text-[var(--text)]">
                      Local mail adapter
                    </p>

                    <p class="mt-0.5">
                      Sent emails are available in the <.link
                        href="/dev/mailbox"
                        class="font-medium text-blue-500 hover:underline"
                      >
                        development mailbox
                      </.link>.
                    </p>
                  </div>
                </div>

                <%!-- Magic link login --%>
                <div class="mt-6">
                  <p class="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)]">
                    Email link
                  </p>

                  <.form
                    :let={f}
                    for={@form}
                    id="login_form_magic"
                    action={~p"/users/log-in"}
                    phx-submit="submit_magic"
                    class="mt-3"
                  >
                    <label
                      for={f[:email].id <> "_magic"}
                      class="mb-2 block text-sm font-medium text-[var(--text)]"
                    >
                      Email
                    </label>

                    <input
                      id={f[:email].id <> "_magic"}
                      name={f[:email].name}
                      value={f[:email].value}
                      readonly={!!@current_scope}
                      type="email"
                      autocomplete="username"
                      spellcheck="false"
                      required
                      phx-mounted={JS.focus()}
                      placeholder="you@example.com"
                      class="w-full rounded-xl border border-[var(--border)] bg-[var(--bg)] px-4 py-3 text-[var(--text)] outline-none transition-colors placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                    />

                    <button
                      type="submit"
                      class="mt-3 flex w-full items-center justify-center gap-2 rounded-xl bg-[var(--accent)] px-4 py-3 font-semibold text-white transition-colors hover:bg-[var(--accent-hover)]"
                    >
                      Email me a login link <.icon name="hero-arrow-right" class="size-4" />
                    </button>
                  </.form>
                </div>

                <%!-- Divider --%>
                <div class="my-6 flex items-center gap-4">
                  <div class="h-px flex-1 bg-[var(--border)]"></div>

                  <span class="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)]">
                    or use password
                  </span>

                  <div class="h-px flex-1 bg-[var(--border)]"></div>
                </div>

                <%!-- Password login --%>
                <.form
                  :let={f}
                  for={@form}
                  id="login_form_password"
                  action={~p"/users/log-in"}
                  phx-submit="submit_password"
                  phx-trigger-action={@trigger_submit}
                >
                  <div>
                    <label
                      for={f[:email].id <> "_password"}
                      class="mb-2 block text-sm font-medium text-[var(--text)]"
                    >
                      Email
                    </label>

                    <input
                      id={f[:email].id <> "_password"}
                      name={f[:email].name}
                      value={f[:email].value}
                      readonly={!!@current_scope}
                      type="email"
                      autocomplete="username"
                      spellcheck="false"
                      required
                      placeholder="you@example.com"
                      class="w-full rounded-xl border border-[var(--border)] bg-[var(--bg)] px-4 py-3 text-[var(--text)] outline-none transition-colors placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                    />
                  </div>

                  <div class="mt-4">
                    <label
                      for={f[:password].id}
                      class="mb-2 block text-sm font-medium text-[var(--text)]"
                    >
                      Password
                    </label>

                    <input
                      id={f[:password].id}
                      name={f[:password].name}
                      type="password"
                      autocomplete="current-password"
                      spellcheck="false"
                      placeholder="••••••••"
                      class="w-full rounded-xl border border-[var(--border)] bg-[var(--bg)] px-4 py-3 text-[var(--text)] outline-none transition-colors placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                    />
                  </div>

                  <button
                    type="submit"
                    name={@form[:remember_me].name}
                    value="true"
                    class="mt-5 flex w-full items-center justify-center gap-2 rounded-xl bg-[var(--accent)] px-4 py-3 font-semibold text-white transition-colors hover:bg-[var(--accent-hover)]"
                  >
                    Log in and stay logged in <.icon name="hero-arrow-right" class="size-4" />
                  </button>

                  <button
                    type="submit"
                    class="mt-2 w-full rounded-xl bg-[var(--surface-hover)] px-4 py-3 font-medium text-[var(--text)] transition-colors hover:bg-[var(--surface-strong)]"
                  >
                    Log in only this time
                  </button>
                </.form>
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
  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  @impl true
  def handle_event("submit_password", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> push_navigate(to: ~p"/users/log-in")}
  end

  defp local_mail_adapter? do
    Application.get_env(:anihub, Anihub.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
