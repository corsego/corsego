// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")

require("stylesheets/application.scss")

import 'bootstrap/dist/js/bootstrap'
import "bootstrap/dist/css/bootstrap";

import "@fortawesome/fontawesome-free/css/all"


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

require("trix")
require("@rails/actiontext")

require("chartkick") // yarn add chartkick chart.js
require("chart.js")

import "../trix-editor-overrides"

require("jquery-ui-dist/jquery-ui");

require("selectize")

import "cocoon-js";

import "youtube"

$(document).on('turbolinks:load', function(){
  $('.lesson-sortable').sortable({
    cursor: "grabbing",
    //cursorAt: { left: 10 },
    placeholder: "ui-state-highlight",
    update: function(e, ui){
      let item = ui.item;
      let item_data = item.data();
      let params = {_method: 'put'};
      params[item_data.modelName] = { row_order_position: item.index() }
      $.ajax({
        type: 'POST',
        url: item_data.updateUrl,
        dataType: 'json',
        data: params
      });
    },
    stop: function(e, ui){
      console.log("stop called when finishing sort of cards");
    }
  });

  $("video").bind("contextmenu",function(){
      return false;
  });

  if ($('.selectize')){
      $('.selectize').selectize({
          sortField: 'text'
      });
  }

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
