defmodule AnihubWeb.UserLive.Login do
  use AnihubWeb, :live_view

  alias Anihub.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl px-3 py-5 sm:px-4">
        <%!-- Simple auth header --%>
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
            class="border border-[var(--border)] bg-[var(--surface)] px-2 py-1 text-sm text-[var(--text-muted)] hover:bg-[var(--surface-hover)] hover:text-[var(--text)]"
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
            Log in
          </span>
        </div>

        <div class="mx-auto max-w-xl border border-[var(--border)] bg-[var(--surface)]">
          <%!-- Panel header --%>
          <div class="old-panel-header px-3 py-2">
            <h1 class="text-sm font-bold uppercase tracking-wide text-[var(--text)]">
              Member login
            </h1>
          </div>

          <div class="p-4 sm:p-5">
            <%= if @current_scope do %>
              <p class="mb-4 text-sm text-[var(--text-muted)]">
                Reauthenticate to continue with this sensitive action.
              </p>
            <% else %>
              <p class="mb-4 text-sm text-[var(--text-muted)]">
                Don't have an account?
                <.link
                  navigate={~p"/users/register"}
                  class="font-semibold text-[var(--accent)] hover:underline"
                >
                  Create one »
                </.link>
              </p>
            <% end %>

            <%!-- Dev mailbox notice --%>
            <div
              :if={local_mail_adapter?()}
              class="mb-4 border border-[var(--border)] bg-[var(--surface-hover)] px-3 py-2 text-xs leading-5 text-[var(--text-muted)]"
            >
              <strong class="text-[var(--text)]">
                Local mail adapter:
              </strong>
              sent emails are available in the <.link
                href="/dev/mailbox"
                class="text-[var(--accent)] hover:underline"
              >
                development mailbox
              </.link>.
            </div>

            <%!-- Magic link login --%>
            <section class="border border-[var(--border)]">
              <div class="old-panel-header px-3 py-1.5">
                <h2 class="text-xs font-bold uppercase text-[var(--text)]">
                  Email login link
                </h2>
              </div>

              <.form
                :let={f}
                for={@form}
                id="login_form_magic"
                action={~p"/users/log-in"}
                phx-submit="submit_magic"
                class="p-3"
              >
                <div class="grid gap-2 sm:grid-cols-[110px_minmax(0,1fr)] sm:items-center">
                  <label
                    for={f[:email].id <> "_magic"}
                    class="text-sm font-semibold text-[var(--text)]"
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
                    class="w-full border border-[var(--border)] bg-[var(--bg)] px-2 py-1.5 text-sm text-[var(--text)] outline-none placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                  />
                </div>

                <div class="mt-3 sm:pl-[118px]">
                  <button
                    type="submit"
                    class="old-button"
                  >
                    Email me a login link →
                  </button>
                </div>
              </.form>
            </section>

            <%!-- Password login --%>
            <section class="mt-4 border border-[var(--border)]">
              <div class="old-panel-header px-3 py-1.5">
                <h2 class="text-xs font-bold uppercase text-[var(--text)]">
                  Password login
                </h2>
              </div>

              <.form
                :let={f}
                for={@form}
                id="login_form_password"
                action={~p"/users/log-in"}
                phx-submit="submit_password"
                phx-trigger-action={@trigger_submit}
                class="p-3"
              >
                <div class="grid gap-2 sm:grid-cols-[110px_minmax(0,1fr)] sm:items-center">
                  <label
                    for={f[:email].id <> "_password"}
                    class="text-sm font-semibold text-[var(--text)]"
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
                    class="w-full border border-[var(--border)] bg-[var(--bg)] px-2 py-1.5 text-sm text-[var(--text)] outline-none placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                  />
                </div>

                <div class="mt-3 grid gap-2 sm:grid-cols-[110px_minmax(0,1fr)] sm:items-center">
                  <label
                    for={f[:password].id}
                    class="text-sm font-semibold text-[var(--text)]"
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
                    class="w-full border border-[var(--border)] bg-[var(--bg)] px-2 py-1.5 text-sm text-[var(--text)] outline-none placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                  />
                </div>

                <div class="mt-4 flex flex-wrap gap-2 sm:pl-[118px]">
                  <button
                    type="submit"
                    name={@form[:remember_me].name}
                    value="true"
                    class="old-button"
                  >
                    Log in and stay logged in
                  </button>

                  <button
                    type="submit"
                    class="border border-[var(--border)] bg-[var(--surface-hover)] px-3 py-1.5 text-sm font-semibold text-[var(--text)] hover:bg-[var(--surface-strong)]"
                  >
                    Log in only this time
                  </button>
                </div>
              </.form>
            </section>
          </div>

          <%!-- Footer --%>
          <div class="border-t border-[var(--border)] bg-[var(--surface-hover)] px-3 py-2 text-center text-xs text-[var(--text-muted)]">
            AniHub tracks your anime library and release schedule.
            It does not host or stream anime.
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
