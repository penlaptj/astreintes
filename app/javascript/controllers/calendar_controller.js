
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["userSelect", "calendarEl"]
  static values = { slots: Array, currentUser: Number, isAdmin: Boolean }

  connect() {
    this.calendar = new FullCalendar.Calendar(this.calendarElTarget, {
      initialView: "dayGridMonth",
      locale: "fr",
      headerToolbar: {
        left: "prev,next today",
        center: "title",
        right: "dayGridMonth,timeGridWeek,multiMonthYear"
      },
      buttonText: {
        today: "Aujourd'hui",
        month: "Mois",
        week: "Semaine",
        year: "année"
      },
      displayEventEnd: true,
      events: this.defaultEvents(),
      eventClick: function(info) {
        let message =
          "Astreinte : " + info.event.title + "\n" +
          "Début : " + info.event.start.toLocaleString("fr-FR") + "\n" +
          "Fin : " + info.event.end.toLocaleString("fr-FR")

        const description = info.event.extendedProps.description
        if (description) {
          message += "\nDescription : " + description
        }

        alert(message)
      },
      height: "auto"
    })

    this.calendar.render()

    // Admin : par défaut on affiche tout le monde (« Tous les utilisateurs »).
    if (this.hasUserSelectTarget) {
      this.userSelectTarget.value = ""
    }
  }

  // Vue par défaut : l'admin voit tout ; le collaborateur voit ses propres
  // créneaux + les créneaux non assignés (disponibles à prendre).
  defaultEvents() {
    if (this.isAdminValue) {
      return this.slotsValue
    }

    return this.slotsValue.filter(
      s => s.userId === this.currentUserValue || s.userId === null
    )
  }

  filter() {
    const userId = this.userSelectTarget.value
    console.log("userId sélectionné:", userId, typeof userId)
    console.log("premier slot userId:", this.slotsValue[0]?.userId, typeof this.slotsValue[0]?.userId)

    const filtered = userId
        ? this.slotsValue.filter(s => String(s.userId) === userId)
        : this.slotsValue

    this.calendar.removeAllEvents()
    this.calendar.addEventSource(filtered)
    }
}