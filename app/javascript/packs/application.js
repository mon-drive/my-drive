// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

//= require rails-ujs
//= require jquery
//= require jquery_ujs
//= require popper
//= require bootstrap-sprockets
//= require activestorage
//= require turbolinks
//= require_tree .

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks";
import * as ActiveStorage from "@rails/activestorage"
import "channels"
import "bootstrap"
import "bootstrap-icons/font/bootstrap-icons.css"
import $ from 'jquery';
import * as bootstrap from 'bootstrap';
window.bootstrap = bootstrap;
// Make jQuery available globally
window.$ = $;
window.jQuery = $;

Rails.start()
ActiveStorage.start()
Turbolinks.start()

document.addEventListener("turbolinks:load", () => {
  document.querySelectorAll('.dropdown-item').forEach(function (item) {
    item.addEventListener('click', function (event) {
      event.preventDefault();
      var locale = event.target.getAttribute('data-locale');

      // Make an AJAX request to set the locale
      fetch('/set_locale', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ locale: locale })
      }).then(function (response) {
        if (response.ok) {
          location.reload(); // Reload the page to apply the new locale
        }
      });
    });
  });
});