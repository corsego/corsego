// frozen_string_literal: true
import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"
import { post } from "@rails/request.js"

// Connects to data-controller="tom-select"
export default class extends Controller {
  static values = {
    createUrl: String,
    createable: { type: Boolean, default: false },
    sortField: { type: String, default: "text" }
  }

  connect() {
    const options = {
      plugins: ["remove_button"],
      sortField: this.sortFieldValue
    }

    if (this.createableValue && this.hasCreateUrlValue) {
      options.create = this.createTag.bind(this)
    }

    this.tomSelect = new TomSelect(this.element, options)
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }

  async createTag(input, callback) {
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
      console.error("Error creating tag:", error)
      callback()
    }
  }
}
