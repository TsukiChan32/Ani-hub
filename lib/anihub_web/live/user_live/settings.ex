defmodule AnihubWeb.UserLive.Settings do
  use AnihubWeb, :live_view

  on_mount {AnihubWeb.UserAuth, :require_sudo_mode}

  alias Anihub.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen px-4 py-6 sm:px-6 sm:py-8">
        <div class="mx-auto max-w-5xl">
          <%!-- Top navigation --%>
          <nav class="mb-10 flex items-center justify-between">
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

            <div class="flex items-center gap-2">
              <.link
                navigate={~p"/"}
                class="rounded-xl px-3 py-2 text-sm font-medium text-[var(--text-muted)] transition-colors hover:bg-[var(--surface-hover)] hover:text-[var(--text)]"
              >
                Back to app
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
            </div>
          </nav>

          <%!-- Header --%>
          <header class="mb-8">
            <p class="text-sm font-semibold uppercase tracking-wider text-[var(--accent)]">
              Account
            </p>

            <h1 class="mt-1 text-3xl font-bold tracking-tight text-[var(--text)] sm:text-4xl">
              Account settings
            </h1>

            <p class="mt-2 max-w-2xl text-sm leading-6 text-[var(--text-muted)] sm:text-base">
              Manage your email address and account password.
            </p>
          </header>

          <%!-- Current account summary --%>
          <section class="mb-6 rounded-2xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-6">
            <div class="flex flex-wrap items-center justify-between gap-4">
              <div>
                <p class="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)]">
                  Signed in as
                </p>

                <p class="mt-1 font-semibold text-[var(--text)]">
                  {@current_email}
                </p>
              </div>

              <div class="flex size-11 items-center justify-center rounded-xl bg-[var(--accent-soft)] text-[var(--accent)]">
                <.icon name="hero-user-circle" class="size-6" />
              </div>
            </div>
          </section>

          <div class="grid gap-6 lg:grid-cols-2">
            <%!-- Email card --%>
            <section class="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-6">
              <div class="mb-6">
                <div class="flex size-10 items-center justify-center rounded-xl bg-blue-500/15 text-blue-500">
                  <.icon name="hero-envelope" class="size-5" />
                </div>

                <h2 class="mt-4 text-xl font-bold text-[var(--text)]">
                  Email address
                </h2>

                <p class="mt-1 text-sm leading-6 text-[var(--text-muted)]">
                  Change the email address associated with your account.
                </p>
              </div>

              <.form
                for={@email_form}
                id="email_form"
                phx-submit="update_email"
                phx-change="validate_email"
              >
                <label
                  for={@email_form[:email].id}
                  class="mb-2 block text-sm font-medium text-[var(--text)]"
                >
                  Email
                </label>

                <input
                  id={@email_form[:email].id}
                  name={@email_form[:email].name}
                  value={@email_form[:email].value}
                  type="email"
                  autocomplete="username"
                  spellcheck="false"
                  required
                  class="w-full rounded-xl border border-[var(--border)] bg-[var(--bg)] px-4 py-3 text-[var(--text)] outline-none transition-colors placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                />

                <%= for error <- @email_form[:email].errors do %>
                  <p class="mt-2 text-sm text-rose-500">
                    {translate_error(error)}
                  </p>
                <% end %>

                <button
                  type="submit"
                  phx-disable-with="Changing..."
                  class="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[var(--accent)] px-4 py-3 font-semibold text-white transition-colors hover:bg-[var(--accent-hover)] disabled:cursor-wait disabled:opacity-70"
                >
                  Change email <.icon name="hero-arrow-right" class="size-4" />
                </button>
              </.form>

              <div class="mt-5 rounded-2xl border border-[var(--border)] bg-[var(--bg)] p-4">
                <div class="flex gap-3">
                  <.icon
                    name="hero-information-circle"
                    class="mt-0.5 size-5 shrink-0 text-[var(--accent)]"
                  />

                  <p class="text-xs leading-5 text-[var(--text-muted)]">
                    We'll send a confirmation link to your new email address before the change is applied.
                  </p>
                </div>
              </div>
            </section>

            <%!-- Password card --%>
            <section class="rounded-3xl border border-[var(--border)] bg-[var(--surface)] p-5 sm:p-6">
              <div class="mb-6">
                <div class="flex size-10 items-center justify-center rounded-xl bg-violet-500/15 text-violet-500">
                  <.icon name="hero-lock-closed" class="size-5" />
                </div>

                <h2 class="mt-4 text-xl font-bold text-[var(--text)]">
                  Password
                </h2>

                <p class="mt-1 text-sm leading-6 text-[var(--text-muted)]">
                  Set or update the password used to sign in to AniHub.
                </p>
              </div>

              <.form
                for={@password_form}
                id="password_form"
                action={~p"/users/update-password"}
                method="post"
                phx-change="validate_password"
                phx-submit="update_password"
                phx-trigger-action={@trigger_submit}
              >
                <input
                  name={@password_form[:email].name}
                  type="hidden"
                  id="hidden_user_email"
                  spellcheck="false"
                  value={@current_email}
                />

                <div>
                  <label
                    for={@password_form[:password].id}
                    class="mb-2 block text-sm font-medium text-[var(--text)]"
                  >
                    New password
                  </label>

                  <input
                    id={@password_form[:password].id}
                    name={@password_form[:password].name}
                    type="password"
                    autocomplete="new-password"
                    spellcheck="false"
                    required
                    placeholder="••••••••"
                    class="w-full rounded-xl border border-[var(--border)] bg-[var(--bg)] px-4 py-3 text-[var(--text)] outline-none transition-colors placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                  />

                  <%= for error <- @password_form[:password].errors do %>
                    <p class="mt-2 text-sm text-rose-500">
                      {translate_error(error)}
                    </p>
                  <% end %>
                </div>

                <div class="mt-4">
                  <label
                    for={@password_form[:password_confirmation].id}
                    class="mb-2 block text-sm font-medium text-[var(--text)]"
                  >
                    Confirm new password
                  </label>

                  <input
                    id={@password_form[:password_confirmation].id}
                    name={@password_form[:password_confirmation].name}
                    type="password"
                    autocomplete="new-password"
                    spellcheck="false"
                    placeholder="••••••••"
                    class="w-full rounded-xl border border-[var(--border)] bg-[var(--bg)] px-4 py-3 text-[var(--text)] outline-none transition-colors placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                  />

                  <%= for error <- @password_form[:password_confirmation].errors do %>
                    <p class="mt-2 text-sm text-rose-500">
                      {translate_error(error)}
                    </p>
                  <% end %>
                </div>

                <button
                  type="submit"
                  phx-disable-with="Saving..."
                  class="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[var(--accent)] px-4 py-3 font-semibold text-white transition-colors hover:bg-[var(--accent-hover)] disabled:cursor-wait disabled:opacity-70"
                >
                  Save password <.icon name="hero-check" class="size-4" />
                </button>
              </.form>

              <div class="mt-5 rounded-2xl border border-[var(--border)] bg-[var(--bg)] p-4">
                <div class="flex gap-3">
                  <.icon
                    name="hero-shield-check"
                    class="mt-0.5 size-5 shrink-0 text-[var(--accent)]"
                  />

                  <p class="text-xs leading-5 text-[var(--text-muted)]">
                    You're in secure mode, so sensitive account changes can be made safely.
                  </p>
                </div>
              </div>
            </section>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        {:ok, _user} ->
          put_flash(socket, :info, "Email changed successfully.")

        {:error, _} ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user

    email_changeset =
      Accounts.change_user_email(
        user,
        %{},
        validate_unique: false
      )

    password_changeset =
      Accounts.change_user_password(
        user,
        %{},
        hash_password: false
      )

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(
        user_params,
        validate_unique: false
      )
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  @impl true
  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params

    user = socket.assigns.current_scope.user

    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(
            changeset,
            :insert
          ),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        info =
          "A link to confirm your email change has been sent to the new address."

        {:noreply, put_flash(socket, :info, info)}

      changeset ->
        {:noreply,
         assign(
           socket,
           :email_form,
           to_form(changeset, action: :insert)
         )}
    end
  end

  @impl true
  def handle_event("validate_password", params, socket) do
    %{"user" => user_params} = params

    password_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_password(
        user_params,
        hash_password: false
      )
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form)}
  end

  @impl true
  def handle_event("update_password", params, socket) do
    %{"user" => user_params} = params

    user = socket.assigns.current_scope.user

    true = Accounts.sudo_mode?(user)

    case Accounts.change_user_password(user, user_params) do
      %{valid?: true} = changeset ->
        {:noreply,
         assign(
           socket,
           trigger_submit: true,
           password_form: to_form(changeset)
         )}

      changeset ->
        {:noreply,
         assign(
           socket,
           password_form: to_form(changeset, action: :insert)
         )}
    end
  end
end
