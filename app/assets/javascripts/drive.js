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
  // Rename
  $('.rename-item').on('click', function() {
    var itemId = $(this).data('id');
    var itemName = prompt('Inserisci il nuovo nome:');
    if (itemName) {
      $.ajax({
        url: '/items/' + itemId + '/rename',
        type: 'PATCH',
        data: {
          item: { name: itemName }
        },
        dataType: 'json',
        success: function(response) {
          if (response.success) {
            $('#item-name-' + itemId).text(response.name);
          } else {
            alert('Errore: ' + response.errors.join(', '));
          }
        }
      });
    }
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
