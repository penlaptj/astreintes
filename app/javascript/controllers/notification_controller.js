import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {

  static targets = ["list", "badge"]

    accept_swap(event) {
      const senderId        = event.currentTarget.dataset.senderId
      const receiverId = event.currentTarget.dataset.receiverId
      const slotId          = event.currentTarget.dataset.slotId
      const notificationId  = event.currentTarget.dataset.notificationId

      fetch(`/notification/create` , {
        method: "POST" ,
        headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ receiver_id: receiverId, slot_id: slotId, notification_type: "accept_assign" })
      })

      fetch(`/notification/${notificationId}/mark_as_read`, {
        method: "POST" ,
        headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
      })

      fetch(`/slots/${slotId}/assign`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ user_id: senderId })
        }).then(r => {
        if (r.ok) {
            location.reload()
        }
      })
    }

    decline_swap(event) {
      const receiverId = event.currentTarget.dataset.receiverId
      const slotId          = event.currentTarget.dataset.slotId
      const notificationId  = event.currentTarget.dataset.notificationId

      fetch(`/notification/create` , {
        method: "POST" ,
        headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ receiver_id: receiverId, slot_id: slotId, notification_type: "refuse_assign" })
      })

      fetch(`/notification/${notificationId}/mark_as_read`, {
        method: "POST" ,
        headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
      }).then(r => {
        if (r.ok) {
            location.reload()
        }
      })
      
    }

    connect() {
    this.subscription = consumer.subscriptions.create("NotificationChannel", {
      received: (data) => {
        console.log("data reçue:", data)
        this.refreshSidebar()
        this.addNotification(data)
        this.updateBadge()
        
      }
    })
  }

    disconnect() {
      this.subscription.unsubscribe()
    }

    addNotification(data) {
      const html = `
        <div class="border border-gray-100 rounded-xl p-4 mb-3 bg-white shadow-sm">
          <p class="text-xs text-gray-400">${data.sender_name} — ${new Date().toLocaleString('fr-FR')}</p>
          <p class="text-sm text-gray-800 mt-1">${data.message || 'Nouvelle notification'}</p>
        </div>
      `
      this.listTarget.insertAdjacentHTML("afterbegin", html)
    }

    updateBadge() {
      const count = parseInt(this.badgeTarget.textContent || "0") + 1
      this.badgeTarget.textContent = count
      this.badgeTarget.classList.remove("hidden")
    }

    refreshSidebar() {
      fetch("/notifications/sidebar")
        .then(r => r.text())
        .then(html => {
          const sidebar = document.querySelector("[data-notification-sidebar]")
          if (sidebar) sidebar.innerHTML = html
        })
    }
}