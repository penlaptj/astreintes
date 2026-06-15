import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "input", "role", "sort", "status", "type"]

  /**
   * User filter
   */
  filter() {
    const search = this.inputTarget.value.toLowerCase()
    const role = this.roleTarget.value.toLowerCase()

    this.rowTargets.forEach(row => {
      const name = row.dataset.name.toLowerCase()
      const userRole = row.dataset.role.toLowerCase()

      const matchSearch = name.includes(search)
      const matchRole = role === "" || userRole === role

      if (matchSearch && matchRole) {
        row.classList.remove("hidden")
      } else {
        row.classList.add("hidden")
      }
    })
  }
  role() {
    const role = this.roleTarget.value

    const url = new URL(window.location.href)
    url.searchParams.set("role", role)
    
    window.location.href= url.toString()
  }


  /**
   * Slots filter
   */
  status() {
    const criterion = this.statusTarget.value

    const url = new URL(window.location.href)
    url.searchParams.set("status", criterion)

    window.location.href = url.toString()
  }
  
  type() {
    const criterion = this.typeTarget.value

    const url = new URL(window.location.href)
    url.searchParams.set("type", criterion)

    window.location.href = url.toString()
  }

  sort() {
    const sortValue = this.sortTarget.value

    const url = new URL(window.location.href)
    url.searchParams.set("sort", sortValue)

    window.location.href = url.toString()
  }
}
