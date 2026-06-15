import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel","button","toggle","menu","slots", "assignModal", "assignSelect", "assignSlotId","roleModal", "roleSelect"]

  showsidebar (event) {
    const id = event.currentTarget.dataset.panel

    // Cache tous les panels
    this.panelTargets.forEach(panel => panel.classList.add("hidden"))

    // Affiche le bon
    const target = this.panelTargets.find(p => p.dataset.panelId === id)
    if (target) target.classList.toggle("hidden")
    
    // reset tout les boutons
    this.buttonTargets.forEach(button => button.classList.remove("bg-gray-800"))

    //mettre en gras le bouton concerné
    event.currentTarget.classList.add("bg-gray-800")

  }


  menudisplay(event) {
    event.stopPropagation()
    
    const id = event.currentTarget.dataset.toggle

    // Cache tous les menus
    this.menuTargets.forEach(menu => menu.classList.add("hidden"))

    // Trouve le bon menu
    const menu = this.menuTargets.find(m => m.dataset.toggleId === id)
    
    if (!menu) {
      console.log("menu introuvable, id cherché:", id)
      return
    }

    // Positionner le menu sous le bouton
    const btn = event.currentTarget.getBoundingClientRect()
    menu.style.position = "fixed"
    menu.style.top = btn.bottom + 1 + "px"
    menu.style.right = (window.innerWidth - btn.right) + "px"

    menu.classList.toggle("hidden")

    this.toggleTargets.forEach(toggle => toggle.classList.remove("bg-gray-400"))
    event.currentTarget.classList.toggle("bg-gray-400")
  }

  close() {
    this.toggleTargets.forEach(toggle => toggle.classList.remove("bg-gray-400"))
    this.menuTargets.forEach(menu => menu.classList.add("hidden"))
    if (this.hasSlotsTarget) {
      this.slotsTarget.classList.add("hidden")
    }
}

  

  stopPropagation(event) {
    event.stopPropagation()
  }

  showSlots(event) {
    event.stopPropagation()
    const userId = event.currentTarget.dataset.userId

    // Ferme le menu déroulant pour qu'il ne recouvre pas la vue de droite.
    this.menuTargets.forEach(menu => menu.classList.add("hidden"))
    this.toggleTargets.forEach(toggle => toggle.classList.remove("bg-gray-400"))

    fetch(`/users/${userId}/slots`)
      .then(r => r.text())
      .then(html => {
        this.slotsTarget.innerHTML = html
        this.slotsTarget.classList.remove("hidden")
      })
  }


  disable(event) {
    event.stopPropagation()
    const userId = event.currentTarget.dataset.userId

    if (!confirm("Désactiver cet utilisateur ?")) return

    fetch(`/users/${userId}/disable`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    }).then(r => {
      if (r.ok) location.reload()
    })
  }

  enable(event) {
    event.stopPropagation()
    const userId = event.currentTarget.dataset.userId

    if (!confirm("Activer cet utilisateur ?")) return

    fetch(`/users/${userId}/enable`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    }).then(r => {
      if (r.ok) location.reload()
    })
  }

  destroy(event) {
    event.stopPropagation()
    const userId = event.currentTarget.dataset.userId

    if (!confirm("Supprimer définitivement cet utilisateur ?")) return

    fetch(`/users/${userId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    }).then(r => {
      if (r.ok) location.reload()
    })
  }

  closeAssign() {
    this.assignModalTarget.classList.add("hidden")
  }

  openAssign(event) {
    event.stopPropagation()
    this.currentSlotId = event.currentTarget.dataset.slotId
    this.assignModalTarget.classList.remove("hidden")
  }

  closeRole() {
    this.roleModalTarget.classList.add("hidden")
  }

  openRole(event) {
    event.stopPropagation()
    this.currentUserId = event.currentTarget.dataset.userId
    this.roleModalTarget.classList.remove("hidden")

  }

  confirmAssign(event) {
    event.stopPropagation()
    const slotId = this.currentSlotId
    const userId = this.assignSelectTarget.value

    fetch(`/slots/${slotId}/assign`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ user_id: userId })
    }).then(r => {
      if (r.ok) {
        this.closeRole()
        location.reload()
      }
    })

    fetch(`/notification/create` , {
      method: "POST" ,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ receiver_id: userId, slot_id: slotId, notification_type: "slot_assigned" })
    }).then(r => {
      if (r.ok) {
        alert("Assignation effectuées !")
        this.closeAssign()
        location.reload()
      }
    })
  }

  changeRole(event) {
    event.stopPropagation()
    const userId = this.currentUserId
    const role = this.roleSelectTarget.value

    fetch(`/users/${userId}/change_role`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ role: role })
    }).then(r => {
      if (r.ok) {
        this.closeRole()
        location.reload()
      }
    })
  }

  

}