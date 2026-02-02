// Stimulus Hello Controller
// A simple smoke test controller to verify Stimulus is working

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  connect() {
    if (this.hasOutputTarget) {
      this.outputTarget.textContent = "Stimulus is working!"
    }
  }

  greet() {
    if (this.hasOutputTarget) {
      this.outputTarget.textContent = "Hello from Stimulus!"
    }
  }
}
