import { Controller } from "@hotwired/stimulus"

// Bascule la visibilité d'un ou plusieurs champs <input type="password">.
// Cibles :
//   - input  : le(s) champ(s) à basculer
//   - label  : (optionnel) texte du bouton ("Afficher" / "Masquer")
export default class extends Controller {
  static targets = ["input", "label"]

  toggle(event) {
    event.preventDefault()
    const shouldShow = this.inputTargets.some(i => i.type === "password")
    const nextType = shouldShow ? "text" : "password"
    this.inputTargets.forEach(input => { input.type = nextType })

    if (this.hasLabelTarget) {
      this.labelTargets.forEach(label => {
        label.textContent = shouldShow ? "Masquer" : "Afficher"
      })
    }
  }
}
