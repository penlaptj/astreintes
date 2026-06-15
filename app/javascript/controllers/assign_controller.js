import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["assignModal", "assignSelect"]

  openAssign(event) {
    event.stopPropagation()
    this.currentSlotId = event.currentTarget.dataset.slotId
    this.assignModalTarget.classList.remove("hidden")
  }

  closeAssign() {
    this.assignModalTarget.classList.add("hidden")
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  confirmAssign(event) {
    event.stopPropagation()
    const slotId = this.currentSlotId
    const userId = this.assignSelectTarget.value

    fetch(`/notification/create` , {
      method: "POST" ,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ receiver_id: userId, slot_id: slotId, notification_type: "swap_request" })
    }).then(r => {
      if (r.ok) {
        alert("Demande d'échange envoyée !")
        this.closeAssign()
        location.reload()
      }
    })
  }
}