import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

    static targets = ["chevron","menu", "chevronDown", "chevronUp", "currentPassword", "password", "confirmation", "message"]

    menudisplay(event) {
        event.stopPropagation()
        
        const id = event.currentTarget.dataset.chevron 
    
        const menu = this.menuTargets.find(m => m.dataset.chevronId === id)
        
        if (!menu) {
          console.log("menu introuvable, id cherché:", id)
          return
        }
        this.chevronDownTargets.find(m => m.dataset.chevronId === id).classList.toggle("hidden")
        this.chevronUpTargets.find(m => m.dataset.chevronId === id).classList.toggle("hidden")
        
    
    
        menu.classList.toggle("hidden")
    
        
    }

    async submit() {
        const currentPassword = this.currentPasswordTarget.value
        const password = this.passwordTarget.value
        const confirmation = this.confirmationTarget.value

        if (!currentPassword) {
        this.showError("Veuillez saisir votre mot de passe actuel")
        return
        }

        if (password !== confirmation) {
        this.showError("Les mots de passe ne correspondent pas")
        return
        }

        if (password.length < 6) {
        this.showError("Le mot de passe doit contenir au moins 6 caractères")
        return
        }

        try {
        const response = await fetch("/users/update_password", {
            method: "PATCH",
            headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document
                .querySelector("meta[name='csrf-token']")
                .content,
            },
            body: JSON.stringify({
            current_password: currentPassword,
            password: password,
            password_confirmation: confirmation,
            }),
        })

        const data = await response.json()

        if (response.ok) {
            this.showSuccess(data.message)
        } else {
            this.showError(data.error)
        }
        } catch (error) {
        this.showError("Erreur serveur")
        }
    }

    showError(message) {
        this.messageTarget.textContent = message
        this.messageTarget.classList.remove("text-green-600")
        this.messageTarget.classList.add("text-red-500")
    }

    showSuccess(message) {
        this.messageTarget.textContent = message
        this.messageTarget.classList.remove("text-red-500")
        this.messageTarget.classList.add("text-green-600")
    }
}