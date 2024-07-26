document.addEventListener('DOMContentLoaded', function() {
  var folderLinks = document.querySelectorAll('#folderTree a[data-bs-toggle="collapse"]');
  folderLinks.forEach(function(link) {
    link.addEventListener('click', function(e) {
      var targetId = link.getAttribute('href').replace('#', '');
      var target = document.getElementById(targetId);
      if (target) {
        var bsCollapse = new bootstrap.Collapse(target);
        bsCollapse.toggle();
      }
    });
  });
});

document.addEventListener('turbolinks:load', function () {
  const folderToggles = document.querySelectorAll('.folder-toggle');
  folderToggles.forEach(toggle => {
    toggle.addEventListener('click', function (event) {
      event.stopPropagation();

      const folderItem = this.closest('.folder-item');
      const contents = folderItem.querySelector('.folder-contents');
      console.log('Folder contents:', contents);

      if (contents) {
        const isVisible = contents.style.display === 'block';
        contents.style.display = isVisible ? 'none' : 'block';
        
        const icon = this.querySelector('i');
        icon.classList.toggle('bi-chevron-down', isVisible);
        icon.classList.toggle('bi-chevron-up', !isVisible);
      } else {
        console.error('Folder contents not found.');
      }
    });
  });
});


$(document).on('turbolinks:load', function() {
  // Get CSRF token from meta tag to avoid security issues
  var csrfToken = $('meta[name="csrf-token"]').attr('content');

  // Rename
  $('.rename-item').on('click', function() {
    var itemId = $(this).data('id');
    var currentName = $('#item-name-' + itemId).text(); // Assuming this is how you get the current name
    
    // Set the item ID and current name in the modal's inputs
    $('#rename-item-id').val(itemId);
    $('#item-name').val(currentName);
    
    // Show the modal
    $('#renameItemModal').modal('show');
    
    // Handle the form submission
    $('#save-changes').off('click').on('click', function() {
      var itemName = $('#item-name').val();
  
      if (itemName) {
        $.ajax({
          url: '/items/' + itemId + '/rename',
          type: 'PATCH',
          data: JSON.stringify({
            item: { name: itemName }
          }),
          contentType: 'application/json',
          dataType: 'json',
          headers: {
            'X-CSRF-Token': csrfToken
          },
          success: function(response) {
            if (response.success) {
              $('#item-name-' + itemId).text(response.name);
              $('#renameItemModal').modal('hide');
            } else {
              alert('Errore: ' + response.errors.join(', '));
            }
          }
        });
      }
    });
  });

  // Share
  $('.share-item').on('click', function() {
    // Implementa la logica di condivisione
  });

  // Export
  $('.export-item').on('click', function() {
    // Implementa la logica di esportazione
  });

  // Properties
  $('.properties-item').on('click', function() {
    var itemId = $(this).data('id');
    $.ajax({
      url: '/items/' + itemId + '/properties',
      type: 'GET',
      dataType: 'json',
      success: function(response) {
        if (response.success) {
          var properties = response.properties;
          var propertiesText = '';
          for (var key in properties) {
            propertiesText += key + ': ' + properties[key] + '\n';
          }
          alert(propertiesText);
        }
      }
    });
  });
});


document.addEventListener('DOMContentLoaded', function() {
  document.getElementById('search-form').addEventListener('submit', function(event) {
    event.preventDefault();
    var query = document.getElementById('search-input').value;
    var url = new URL(this.action);
    url.searchParams.set('search', query);
    window.location.href = url.toString();
  });
});

function handleFileSelect() {
  var fileInput = document.getElementById('file-input');
  if (fileInput.files.length > 0) { // Verifica se è stato selezionato un file
    document.getElementById('upload-form').submit();
  } else {
    alert('Seleziona un file prima di procedere.');
  }
}

function apri_modal(id){
  modal = new bootstrap.Modal(document.getElementById(id));
  modal.show();  
}