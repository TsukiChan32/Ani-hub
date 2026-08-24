// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
//
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a
// separate `app.css` file.
//
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"

// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import { hooks as colocatedHooks } from "phoenix-colocated/anihub"
import topbar from "../vendor/topbar"

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content")

const LocalCalendar = {
  mounted() {
    this.filter = "all"
    this.renderCalendar()

    this.el.addEventListener("click", (event) => {
      const button = event.target.closest("[data-calendar-filter]")

      if (!button) return

      this.filter = button.dataset.calendarFilter
      this.renderCalendar()
    })
  },
  updated() {
    this.renderCalendar()
  },


  renderCalendar() {
    const root = this.el
    const filterButtons =
      root.querySelectorAll("[data-calendar-filter]")

    filterButtons.forEach((button) => {
      const active =
        button.dataset.calendarFilter === this.filter

      if (active) {
        button.classList.add(
          "bg-[var(--accent-soft)]",
          "text-[var(--accent)]"
        )

        button.classList.remove(
          "text-[var(--text-muted)]"
        )
      } else {
        button.classList.remove(
          "bg-[var(--accent-soft)]",
          "text-[var(--accent)]"
        )

        button.classList.add(
          "text-[var(--text-muted)]"
        )
      }
    })

    const daySections = Array.from(
      root.querySelectorAll("[data-calendar-day]")
    )

    const dayMap = new Map()

    daySections.forEach((section) => {
      const date = section.dataset.calendarDay
      const results = section.querySelector("[data-day-results]")
      const empty = section.querySelector("[data-day-empty]")
      const count = section.querySelector("[data-release-count]")
      const todayBadge = section.querySelector("[data-today-badge]")

      results.innerHTML = ""
      empty.classList.remove("hidden")
      count.textContent = "0 releases"

      dayMap.set(date, {
        section,
        results,
        empty,
        count,
        todayBadge,
        releases: 0,
      })
    })

    const today = this.localDateKey(new Date())

    dayMap.forEach((day, date) => {
      if (date === today) {
        day.todayBadge.classList.remove("hidden")

        day.section.classList.add(
          "rounded-2xl",
          "border",
          "border-[var(--accent)]",
          "bg-[var(--accent-soft)]",
          "p-5"
        )
      } else {
        day.todayBadge.classList.add("hidden")

        day.section.classList.remove(
          "rounded-2xl",
          "border",
          "border-[var(--accent)]",
          "bg-[var(--accent-soft)]",
          "p-5"
        )
      }
    })
    const airings = Array.from(
      root.querySelectorAll("[data-airing]")
    )

    airings.forEach((airing) => {
      const timestamp = Number(airing.dataset.airingAt) * 1000
      const date = new Date(timestamp)
      const dateKey = this.localDateKey(date)

      const day = dayMap.get(dateKey)

      if (!day) return

      day.releases += 1

      const hours = String(date.getHours()).padStart(2, "0")
      const minutes = String(date.getMinutes()).padStart(2, "0")

      const title = airing.dataset.title
      const mediaId = airing.dataset.mediaId
      const cover = airing.dataset.cover
      const episode = airing.dataset.episode
      const watching =
        airing.dataset.libraryStatus === "watching"
      if (this.filter === "watching" && !watching) {
        return
      }

      const card = document.createElement("a")
      card.href = `/anime/${mediaId}`

      card.className = [
        "group",
        "flex",
        "gap-4",
        "rounded-2xl",
        "border",
        "border-[var(--border)]",
        "bg-[var(--surface)]",
        "p-3",
        "transition-colors",
        "hover:bg-[var(--surface-hover)]",
      ].join(" ")

      const img = document.createElement("img")
      img.src = cover
      img.alt = title
      img.className =
        "h-24 w-16 shrink-0 rounded-xl object-cover"

      const content = document.createElement("div")
      content.className = "min-w-0 flex-1"

      const heading = document.createElement("h3")
      heading.className =
        "line-clamp-2 font-semibold text-[var(--text)] transition-colors group-hover:text-[var(--accent)]"
      heading.textContent = title
      const badges = document.createElement("div")
      badges.className = "mt-2 flex flex-wrap gap-2"

      if (watching) {
        const watchingBadge = document.createElement("span")

        watchingBadge.className =
          "rounded-lg bg-blue-500/15 px-2 py-1 text-xs font-semibold text-blue-500"

        watchingBadge.textContent = "Watching"

        badges.appendChild(watchingBadge)
      }

      const metadata = document.createElement("div")
      metadata.className =
        "mt-2 flex flex-wrap items-center gap-2 text-sm text-[var(--text-muted)]"

      const episodeSpan = document.createElement("span")
      episodeSpan.textContent = `Episode ${episode}`

      const separator = document.createElement("span")
      separator.className = "text-[var(--border)]"
      separator.textContent = "•"

      const timeSpan = document.createElement("span")
      timeSpan.textContent = `${hours}:${minutes}`

      metadata.append(
        episodeSpan,
        separator,
        timeSpan
      )
      content.append(heading)

      if (watching) {
        content.append(badges)
      }

      content.append(metadata)
      card.append(
        img,
        content
      )

      day.results.appendChild(card)
      day.empty.classList.add("hidden")
    })

    dayMap.forEach((day) => {
      const word =
        day.releases === 1
          ? "release"
          : "releases"

      day.count.textContent =
        `${day.releases} ${word}`
    })
  },

  localDateKey(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")

    return `${year}-${month}-${day}`
  },
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,

  params: {
    _csrf_token: csrfToken,
  },

  hooks: {
    ...colocatedHooks,
    LocalCalendar,
  },
})

// Show progress bar on live navigation and form submits.
topbar.config({
  barColors: {
    0: "#29d",
  },
  shadowColor: "rgba(0, 0, 0, .3)",
})

window.addEventListener(
  "phx:page-loading-start",
  _info => topbar.show(300)
)

window.addEventListener(
  "phx:page-loading-stop",
  _info => topbar.hide()
)

// Connect if there are any LiveViews on the page.
liveSocket.connect()

// Expose liveSocket on window for web console debug logs
// and latency simulation:
//
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
// >> liveSocket.disableLatencySim()

window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
// 1. stream server logs to the browser console
// 2. click on elements to jump to their definitions in your code editor

if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs()

      // Open configured PLUG_EDITOR at file:line
      // of the clicked element's HEEx component.
      //
      // * click with "c" key pressed to open at caller location
      // * click with "d" key pressed to open at function component definition

      let keyDown

      window.addEventListener(
        "keydown",
        e => keyDown = e.key
      )

      window.addEventListener(
        "keyup",
        _e => keyDown = null
      )

      window.addEventListener(
        "click",
        e => {
          if (keyDown === "c") {
            e.preventDefault()
            e.stopImmediatePropagation()
            reloader.openEditorAtCaller(e.target)
          } else if (keyDown === "d") {
            e.preventDefault()
            e.stopImmediatePropagation()
            reloader.openEditorAtDef(e.target)
          }
        },
        true
      )

      window.liveReloader = reloader
    }
  )
}

// ========================================
// ANIHUB THEME
// ========================================

const applyTheme = (theme) => {
  const root = document.documentElement
  const darkIcon = document.querySelector(".theme-icon-dark")
  const lightIcon = document.querySelector(".theme-icon-light")

  if (theme === "dark") {
    root.classList.add("dark")

    darkIcon?.classList.add("hidden")
    lightIcon?.classList.remove("hidden")
  } else {
    root.classList.remove("dark")

    darkIcon?.classList.remove("hidden")
    lightIcon?.classList.add("hidden")
  }
}

const savedTheme =
  localStorage.getItem("anihub-theme")

const initialTheme =
  savedTheme ||
  (
    window
      .matchMedia("(prefers-color-scheme: dark)")
      .matches
      ? "dark"
      : "light"
  )

applyTheme(initialTheme)

document.addEventListener("click", (event) => {
  const button =
    event.target.closest("#theme-toggle")

  if (!button) return

  const newTheme =
    document.documentElement.classList.contains("dark")
      ? "light"
      : "dark"

  localStorage.setItem(
    "anihub-theme",
    newTheme
  )

  applyTheme(newTheme)
})