// Stimulus controllers index
// This file loads and registers all Stimulus controllers

import { Application } from "@hotwired/stimulus"

// Start the Stimulus application
const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Import and register controllers
import HelloController from "./hello_controller"
import TomSelectController from "./tom_select_controller"
application.register("hello", HelloController)
application.register("tom-select", TomSelectController)

export { application }
