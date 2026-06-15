import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["button", "intervalModal", "startsAt", "endsAt", "recap", "recapContent", "recapTitle", "chevron", "recapContentDetail", "chevronLeft", "chevronDown"]

    connect(){
      this.showRecap()
    }

    closeInterval (event) {
      this.intervalModalTarget.classList.add("hidden")
    }

    openInterval(event) {
      this.stopPropagation(event)
      this.currentUserId = event.currentTarget.dataset.userId 
      this.intervalModalTarget.classList.remove("hidden")
    }

    stopPropagation(event) {
      event.stopPropagation()
    }

    showRecap() {
      const startsAt = this.startsAtTarget.value
      const endsAt = this.endsAtTarget.value

      if (!startsAt || !endsAt) return

      const url = new URL(window.location.href)
      
      // Ne redirige que si les params ont changé
      if (url.searchParams.get("starts_at") === startsAt && 
          url.searchParams.get("ends_at") === endsAt) return

      url.searchParams.set("starts_at", startsAt)
      url.searchParams.set("ends_at", endsAt)
      window.location.href = url.toString()
    }

    closeRecap() {
    this.recapTarget.classList.add("hidden")
    }

    details(event) {
      const startsAt = event.currentTarget.dataset.startsAt
      const endsAt = event.currentTarget.dataset.endsAt
      const userId = event.currentTarget.dataset.userId
      const target = this.recapContentDetailTargets.find(t => t.dataset.userId === userId)
      const chevronLeft = this.chevronLeftTargets.find(t => t.dataset.userId === userId)
      const chevronDown = this.chevronDownTargets.find(t => t.dataset.userId === userId)
      
      fetch(`/users/${userId}/slots?starts_at=${startsAt}&ends_at=${endsAt}`)
        .then(r => r.text())
        .then(html => {
          target.querySelector("td").innerHTML = html
          target.classList.toggle("hidden")
          chevronLeft.classList.toggle("hidden")
          chevronDown.classList.toggle("hidden")
          target.classList.add("bg-black/10", "rounded-xl")
        })
    }
        
}