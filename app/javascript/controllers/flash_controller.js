import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.close(), 5000)
  }

  disconnect() {
    clearTimeout(this.timeout)
    clearTimeout(this.removalTimeout)
  }

  close() {
    this.element.classList.remove("show")
    this.removalTimeout = setTimeout(() => this.element.remove(), 200)
  }
}
