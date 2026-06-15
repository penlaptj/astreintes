import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  toggle(event) {
    event.stopPropagation()
    const menu = this.menuTarget
    const btn = event.currentTarget.getBoundingClientRect()

    // Positionner le menu sous le bouton
    menu.style.position = "fixed"
    menu.style.top = btn.bottom + 8 + "px"
    menu.style.right = (window.innerWidth - btn.right) + "px"

    menu.classList.toggle("hidden")
  }

  close() {
    this.menuTarget.classList.add("hidden")
  }
}