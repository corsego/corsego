// Corsego Application JavaScript
// Bundled with Bun

// jQuery - must be loaded first and made global for Bootstrap 4 and other plugins
import jQuery from "jquery"
window.$ = window.jQuery = jQuery

// Popper.js for Bootstrap dropdowns/tooltips
import Popper from "popper.js"
window.Popper = Popper

// Turbo for SPA-like navigation
import "@hotwired/turbo-rails"

// Active Storage for file uploads
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()

// Action Cable (import consumer directly, no channels currently used)
import "./channels/consumer"

// Bootstrap JS (requires jQuery and Popper)
import "bootstrap/dist/js/bootstrap"

// Trix editor and ActionText
import "trix"
import "@rails/actiontext"

// Charts
import "chartkick"
import "chart.js"

// Custom Trix overrides with YouTube embed
import "./trix-editor-overrides"

// jQuery UI for sortable
import "jquery-ui-dist/jquery-ui"

// Selectize for enhanced dropdowns
import "selectize"

// Cocoon for nested forms
import "cocoon-js"

// YouTube embed functionality
import "./youtube"

// Use the imported jQuery for all code below
const $ = jQuery

// Document ready handler for Turbo
document.addEventListener('turbo:load', function(){

  // Re-initialize cocoon for dynamically loaded content
  $(document).off('click.cocoon').on('click.cocoon', '.add_fields', function(e) {
    e.preventDefault();
    const $this = $(this);
    const assoc = $this.data('association');
    const content = $this.data('association-insertion-template');
    const insertionMethod = $this.data('association-insertion-method') || 'before';
    const insertionNode = $this.data('association-insertion-node') || $this;
    const insertionTraversal = $this.data('association-insertion-traversal');

    let target = insertionNode;
    if (insertionTraversal) {
      target = $this[insertionTraversal](insertionNode);
    } else if (typeof insertionNode === 'string') {
      target = $(insertionNode);
    }

    const regexp = new RegExp('new_' + assoc, 'g');
    const newId = new Date().getTime();
    const newContent = content.replace(regexp, newId);

    const $newContent = $(newContent);
    target[insertionMethod]($newContent);
    $newContent.trigger('cocoon:after-insert');
  });

  $(document).off('click.cocoon-remove').on('click.cocoon-remove', '.remove_fields', function(e) {
    e.preventDefault();
    const $this = $(this);
    const wrapper = $this.closest('.nested-fields');
    const destroyField = wrapper.find('input[type=hidden][name*="_destroy"]');

    if (destroyField.length) {
      destroyField.val('1');
      wrapper.hide();
    } else {
      wrapper.remove();
    }
    wrapper.trigger('cocoon:after-remove');
  });

  // Chapter drag-drop sorting
  $('.chapter-sortable').sortable({
    axis        : "y",
    cursor      : "grabbing",
    placeholder : "ui-state-highlight",

    update: function(_, ui){
      let item      = ui.item
      let itemData  = item.data()
      let params    = { _method: 'put' }

      params[itemData.modelName] = { row_order_position: item.index() }

      $.ajax({
        type     : 'POST',
        url      : itemData.updateUrl,
        dataType : 'json',
        data     : params
      })
    },
  })

  // Lesson drag-drop sorting with cross-chapter support
  $('.lesson-sortable').sortable({
    axis        : "y",
    cursor      : "grabbing",
    placeholder : "ui-state-highlight",
    connectWith : '.lesson-sortable',

    update: function(_, ui){
      if (ui.sender) return

      let item      = ui.item
      let itemData  = item.data()
      let chapterID    = item.parents('.ui-sortable-handle').eq(0).data().id
      let params    = { _method: 'put' }

      params[itemData.modelName] = { row_order_position: item.index(), chapter_id: chapterID }

      $.ajax({
        type     : 'POST',
        url      : itemData.updateUrl,
        dataType : 'json',
        data     : params
      })
    }
  })

  // Disable right-click on videos
  $("video").bind("contextmenu",function(){
      return false;
  });

  // Initialize selectize dropdowns
  if ($('.selectize')){
      $('.selectize').selectize({
          sortField: 'text'
      });
  }

  // Selectize with dynamic tag creation
  $(".selectize-tags").selectize({
    create: function(input, callback) {
      $.post('/tags.json', { tag: { name: input } })
        .done(function(response){
          console.log(response)
          callback({value: response.id, text: response.name });
        })
    }
  });

});

// Service Worker registration
if ("serviceWorker" in navigator) {
  navigator.serviceWorker
    .register("/service-worker.js")
    .then((registration) => {
      registration.addEventListener("updatefound", () => {
        const installingWorker = registration.installing;
        console.log(
          "A new service worker is being installed:",
          installingWorker,
        );
      });
    })
    .catch((error) => {
      console.error(`Service worker registration failed: ${error}`);
    });
} else {
  console.error("Service workers are not supported.");
}
