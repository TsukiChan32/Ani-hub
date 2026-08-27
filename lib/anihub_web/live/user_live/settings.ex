defmodule AnihubWeb.UserLive.Settings do
  use AnihubWeb, :live_view

  on_mount {AnihubWeb.UserAuth, :require_sudo_mode}

  alias Anihub.Accounts

@impl true
def render(assigns) do
  ~H"""
  <Layouts.app flash={@flash} current_scope={@current_scope}>
    <div class="mx-auto max-w-4xl px-3 py-5 sm:px-4">
      <%!-- Header --%>
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

        <div class="flex items-center gap-2">
          <.link
            navigate={~p"/"}
            class="text-sm text-[var(--accent)] hover:underline"
          >
            Back to app »
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
      </div>

      <%!-- Breadcrumb --%>
      <div class="mb-3 text-xs text-[var(--text-muted)]">
        <.link navigate={~p"/"} class="text-[var(--accent)] hover:underline">
          Home
        </.link>

        <span class="mx-1">»</span>

        <span class="text-[var(--text)]">
          Account settings
        </span>
      </div>

      <%!-- Main panel --%>
      <section class="border border-[var(--border)] bg-[var(--surface)]">
        <div class="old-panel-header px-3 py-2">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <h1 class="text-sm font-bold uppercase tracking-wide text-[var(--text)]">
                Account settings
              </h1>

              <p class="mt-0.5 text-xs text-[var(--text-muted)]">
                Manage your email address and account password.
              </p>
            </div>
          </div>
        </div>

        <%!-- Account summary --%>
        <div class="border-b border-[var(--border)] px-3 py-3">
          <dl class="grid gap-2 text-sm sm:grid-cols-[130px_minmax(0,1fr)]">
            <dt class="font-semibold text-[var(--text-muted)]">
              Signed in as
            </dt>

            <dd class="font-semibold text-[var(--text)]">
              {@current_email}
            </dd>
          </dl>
        </div>

        <div class="p-3 sm:p-4">
          <%!-- Change email --%>
          <section class="border border-[var(--border)]">
            <div class="old-panel-header px-3 py-1.5">
              <h2 class="text-xs font-bold uppercase text-[var(--text)]">
                Change email address
              </h2>
            </div>

            <div class="p-3">
              <p class="mb-3 text-sm text-[var(--text-muted)]">
                Change the email address associated with your account.
              </p>

              <.form
                for={@email_form}
                id="email_form"
                phx-submit="update_email"
                phx-change="validate_email"
              >
                <div class="grid gap-2 sm:grid-cols-[130px_minmax(0,1fr)] sm:items-center">
                  <label
                    for={@email_form[:email].id}
                    class="text-sm font-semibold text-[var(--text)]"
                  >
                    Email
                  </label>

                  <div>
                    <input
                      id={@email_form[:email].id}
                      name={@email_form[:email].name}
                      value={@email_form[:email].value}
                      type="email"
                      autocomplete="username"
                      spellcheck="false"
                      required
                      class="w-full border border-[var(--border)] bg-[var(--bg)] px-2 py-1.5 text-sm text-[var(--text)] outline-none focus:border-[var(--accent)]"
                    />

                    <%= for error <- @email_form[:email].errors do %>
                      <p class="mt-1 text-xs text-rose-500">
                        {translate_error(error)}
                      </p>
                    <% end %>
                  </div>
                </div>

                <div class="mt-3 sm:pl-[138px]">
                  <button
                    type="submit"
                    phx-disable-with="Changing..."
                    class="old-button"
                  >
                    Change email →
                  </button>
                </div>
              </.form>

              <div class="mt-3 border-t border-[var(--border)] pt-2 text-xs leading-5 text-[var(--text-muted)]">
                A confirmation link will be sent to your new email address before the change is applied.
              </div>
            </div>
          </section>

          <%!-- Change password --%>
          <section class="mt-4 border border-[var(--border)]">
            <div class="old-panel-header px-3 py-1.5">
              <h2 class="text-xs font-bold uppercase text-[var(--text)]">
                Change password
              </h2>
            </div>

            <div class="p-3">
              <p class="mb-3 text-sm text-[var(--text-muted)]">
                Set or update the password used to sign in to AniHub.
              </p>

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

                <div class="grid gap-2 sm:grid-cols-[130px_minmax(0,1fr)] sm:items-start">
                  <label
                    for={@password_form[:password].id}
                    class="pt-1.5 text-sm font-semibold text-[var(--text)]"
                  >
                    New password
                  </label>

                  <div>
                    <input
                      id={@password_form[:password].id}
                      name={@password_form[:password].name}
                      type="password"
                      autocomplete="new-password"
                      spellcheck="false"
                      required
                      placeholder="••••••••"
                      class="w-full border border-[var(--border)] bg-[var(--bg)] px-2 py-1.5 text-sm text-[var(--text)] outline-none placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                    />

                    <%= for error <- @password_form[:password].errors do %>
                      <p class="mt-1 text-xs text-rose-500">
                        {translate_error(error)}
                      </p>
                    <% end %>
                  </div>
                </div>

                <div class="mt-3 grid gap-2 sm:grid-cols-[130px_minmax(0,1fr)] sm:items-start">
                  <label
                    for={@password_form[:password_confirmation].id}
                    class="pt-1.5 text-sm font-semibold text-[var(--text)]"
                  >
                    Confirm password
                  </label>

                  <div>
                    <input
                      id={@password_form[:password_confirmation].id}
                      name={@password_form[:password_confirmation].name}
                      type="password"
                      autocomplete="new-password"
                      spellcheck="false"
                      placeholder="••••••••"
                      class="w-full border border-[var(--border)] bg-[var(--bg)] px-2 py-1.5 text-sm text-[var(--text)] outline-none placeholder:text-[var(--text-muted)] focus:border-[var(--accent)]"
                    />

                    <%= for error <- @password_form[:password_confirmation].errors do %>
                      <p class="mt-1 text-xs text-rose-500">
                        {translate_error(error)}
                      </p>
                    <% end %>
                  </div>
                </div>

                <div class="mt-3 sm:pl-[138px]">
                  <button
                    type="submit"
                    phx-disable-with="Saving..."
                    class="old-button"
                  >
                    Save password →
                  </button>
                </div>
              </.form>

              <div class="mt-3 border-t border-[var(--border)] pt-2 text-xs leading-5 text-[var(--text-muted)]">
                Secure mode is active. Sensitive account changes are currently allowed.
              </div>
            </div>
          </section>
        </div>

        <div class="border-t border-[var(--border)] bg-[var(--surface-hover)] px-3 py-2 text-xs text-[var(--text-muted)]">
          Account changes may require confirmation before taking effect.
        </div>
      </section>
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
