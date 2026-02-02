import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"
import { post } from "@rails/request.js"

// Connects to data-controller="tom-select"
export default class extends Controller {
  static values = {
    createUrl: String,
    sortField: { type: String, default: "text" }
  }

  connect() {
    this.initializeTomSelect()
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }

  initializeTomSelect() {
    const options = {
      sortField: { field: this.sortFieldValue, direction: "asc" }
    }

    if (this.hasCreateUrlValue) {
      options.create = this.createOption.bind(this)
    }

    this.tomSelect = new TomSelect(this.element, options)
  }

  async createOption(input, callback) {
    try {
      const response = await post(this.createUrlValue, {
        body: JSON.stringify({ tag: { name: input } }),
        contentType: "application/json",
        responseKind: "json"
      })

      if (response.ok) {
        const data = await response.json
        callback({ value: data.id, text: data.name })
      } else {
        callback()
      }
    } catch (error) {
      console.error("Failed to create option:", error)
      callback()
    }
  }
}
