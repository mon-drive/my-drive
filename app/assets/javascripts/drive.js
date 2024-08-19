

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
    $('#item-name').val(currentName);
    
    // Show the modal
    $('#renameItemModal').modal('show');
    
    // Handle the form submission 
    $('#rename-item-form').on('submit', function(event) {
      event.preventDefault();
  
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
      location.reload();
    });

    // Add event listener for the "Rinomina" button click
    document.getElementById('save-changes').addEventListener('click', function() {
      var renameItemForm = document.getElementById('rename-item-form');
      renameItemForm.dispatchEvent(new Event('submit'));
    });

  });

  // // Share
  // $('.share-item').on('click', function() {
  //   // Implementa la logica di condivisione
  // });

  // // Export
  // $('.export-item').on('click', function() {
  //   // Implementa la logica di esportazione
  // });

  // Properties
  $('.properties-item').on('click', function() {
    var itemId = $(this).data('id');
    var isFolder = $(this).data('is-folder');
    if(isFolder == "application/vnd.google-apps.folder"){
      isFolder = true;
    }else{
      isFolder = false;
    }
    $.ajax({
      url: '/items/' + itemId + '/properties',
      type: 'GET',
      dataType: 'json',
      success: function(data){
        // Populate the modal with the file details
        $('#file-name').text(data.name);
        $('#file-mime_type').text(data.mime_type);
        $('#file-size').text(get_file_size(data.size));
        $('#file-created_time').text(new Date(data.created_time).toLocaleString());
        $('#file-modified_time').text(new Date(data.modified_time).toLocaleString());
        
        var ownersText = data.owners.map(owner => owner.display_name + " (" + owner.email + ")").join(", ");
        $('#file-owners').text(ownersText);
        
        var permissionsText = data.permissions.map(permission => {
          return permission.role + " (" + permission.type + ")";
        }).join(", ");
        
        $('#file-role').text(permissionsText);
        $('#file-shared').text((data.shared ? "Yes" : "No"));

        if(isFolder){
          $('#file-contains').text(data.folders + " cartelle, " + data.files + " file");
        }else{
          $('#file-contains').text("-");
        }
        
        $('#filePropertiesModal').modal('show');
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

function handleFolderSelect() {
  var folderInput = document.getElementById('folder-input');
  if (folderInput.files.length > 0) {
      // Imposta il nome della cartella
      var folderPath = folderInput.files[0].webkitRelativePath;
      var folderName = folderPath.split('/')[0];
      document.getElementById('folder_name').value = folderName;

      // Invia il modulo
      document.getElementById('upload-folder-form').submit();
  } else {
      alert('Seleziona una cartella prima di procedere.');
  }
}

function apri_modal(id){
  modal = new bootstrap.Modal(document.getElementById(id));
  modal.show();  
}

function get_file_size(size){
  //gets file size in bytes and returns a human readable format
  let human_size = 0;
  
  if(size < 1024){
    human_size + ' B';
  }
  else if(size < 1048576){
    human_size = (size / 1024).toFixed(2) + ' KB';
  }
  else if(size < 1073741824){
    human_size = (size / 1048576).toFixed(2) + ' MB';
  }
  else{
    human_size = (size / 1073741824).toFixed(2) + ' GB';
  } 

  return human_size;
}

document.addEventListener('DOMContentLoaded', function() {
  const shareItemButtons = document.querySelectorAll('.share-item');
  const shareFileButton = document.getElementById('share-file');
  const shareForm = document.getElementById('share-item-form');
  let currentFileId = null;

  shareItemButtons.forEach(button => {
    button.addEventListener('click', function() {
      currentFileId = this.getAttribute('data-id');
      const shareModal = new bootstrap.Modal(document.getElementById('shareItemModal'));
      shareModal.show();
    });
  });

  shareFileButton.addEventListener('click', function() {
    const email = shareForm.querySelector('#share-email').value;
    const permission = shareForm.querySelector('#share-permission').value;
    const notify = shareForm.querySelector('#share-notify').checked;
    const message = shareForm.querySelector('#share-message').value;
    const token = shareForm.querySelector('input[name="authenticity_token"]').value;

    fetch('/share', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token
      },
      body: JSON.stringify({ file_id: currentFileId, email: email, permission: permission, notify: notify, message: message })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        shareForm.reset();
        alert('File condiviso con successo.');
      } else {
        alert('Errore durante la condivisione del file.');
      }
    });
  });
});




//export file

document.querySelectorAll('.export-item').forEach(item => {
  item.addEventListener('click', function(event) {
    event.preventDefault();
    apri_modal('md_export');
    const fileId = this.getAttribute('data-id');
    const type = this.getAttribute('type');



    fetch('/export', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ id: fileId, type: type })
    })
    .then(response => {
      if (!response.ok) {
        console.error('Error:', error);
        const modal = document.getElementById('md_export');
        const bootstrapModal = bootstrap.Modal.getInstance(modal);
        bootstrapModal.hide();
        throw new Error('Network response was not ok');
      }
      const modal = document.getElementById('md_export');
      const bootstrapModal = bootstrap.Modal.getInstance(modal);
      bootstrapModal.hide();
      const fileName = response.headers.get('Content-Disposition').split('filename=')[1].replace(/"/g, '').split(';')[0];
      return response.blob().then(blob => ({ blob, fileName }));
    })
    .then(({ blob, fileName }) => {
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.style.display = 'none';
      a.href = url;
      a.download = fileName;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);

    })
    .catch(error => {

      alert('Si è verificato un errore durante la conversione del file.');
    });
  });
});



//export folder

document.querySelectorAll('.export-folder').forEach(item => {
  item.addEventListener('click', function(event) {
    event.preventDefault();
    
    apri_modal('md_export');
    const folderId = this.getAttribute('data-id');

  

    fetch('/export_folder', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      },
      body: JSON.stringify({ id: folderId })
    })
    .then(response => {
      if (!response.ok) {
        console.error('Error:', error);
        const modal = document.getElementById('md_export');
        const bootstrapModal = bootstrap.Modal.getInstance(modal);
        bootstrapModal.hide();
        throw new Error('Network response was not ok');
      }
      const modal = document.getElementById('md_export');
      const bootstrapModal = bootstrap.Modal.getInstance(modal);
      bootstrapModal.hide();
      const fileName = response.headers.get('Content-Disposition')
                      .split('filename=')[1]
                      .replace(/"/g, '')
                      .split(';')[0];
      return response.blob().then(blob => ({ blob, fileName }));
    })
    .then(({ blob, fileName }) => {
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.style.display = 'none';
      a.href = url;
      a.download = fileName;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
    })
    .catch(error => {

      alert('Si è verificato un errore durante l\'esportazione della cartella.');
    });

  });
});




//gestione sottomenu
$(document).ready(function() {
  // Funzione per mostrare il sottomenu
  function showSubmenu(submenu, triggerElement) {
    $('.dropdown-submenu .submenu').not(submenu).hide();
    submenu.removeClass('submenu-left submenu-right');

    var submenuWidth = submenu.outerWidth();
    var distanceToRight = $(window).width() - (triggerElement.offset().left + triggerElement.outerWidth());

    if (distanceToRight < submenuWidth) {
      submenu.addClass('submenu-left');
    } else {
      submenu.addClass('submenu-right');
    }

    var topPosition = triggerElement.position().top;
    submenu.css('top', topPosition);
    submenu.show();
  }

  // Apre il sottomenu al click
  $('.dropdown-submenu > a').on('click', function(e) {
    e.stopPropagation();
    e.preventDefault();

    const $submenu = $(this).next('.submenu');
    showSubmenu($submenu, $(this));
  });

  // Apre il sottomenu al passaggio del mouse
  $('.dropdown-submenu').on('mouseenter', function() {
    const $submenu = $(this).children('.submenu');
    const $triggerElement = $(this).children('a');
    showSubmenu($submenu, $triggerElement);
  });

  // Chiude il sottomenu quando si esce con il mouse
  $('.dropdown-submenu').on('mouseleave', function() {
    const $submenu = $(this).children('.submenu');
    $submenu.hide();
  });

  // Nasconde il sottomenu quando il dropdown viene chiuso
  $('.dropdown').on('hidden.bs.dropdown', function () {
    $('.dropdown-submenu .submenu').hide();
  });

  // Nasconde il sottomenu quando si clicca fuori
  $(document).on('click', function (e) {
    if (!$(e.target).closest('.dropdown-submenu').length) {
      $('.dropdown-submenu .submenu').hide();
    }
  });

});

//gestione ordinamento

document.addEventListener("DOMContentLoaded", function() {
  const orderSelector = document.getElementById('order-selector');
  const itemsContainer = document.getElementById('items-container');

  orderSelector.addEventListener('change', function() {
    const orderBy = this.value;
    const items = Array.from(itemsContainer.children);

    items.sort((a, b) => {
      const nameA = a.dataset.name;
      const nameB = b.dataset.name;

      if (orderBy === 'asc') {
        return nameA.localeCompare(nameB);
      } else if (orderBy === 'desc') {
        return nameB.localeCompare(nameA);
      }
    });

    // Rimuovi e riaggiungi gli elementi nell'ordine corretto
    itemsContainer.innerHTML = '';
    items.forEach(item => itemsContainer.appendChild(item));
  });
});

document.getElementById('editNameForm').addEventListener('submit', function(event) {
  event.preventDefault();
  var newName = document.getElementById('newName').value;

  fetch('/update_name', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    },
    body: JSON.stringify({ username: newName })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      document.getElementById('nome').textContent = newName;
      var modal = bootstrap.Modal.getInstance(document.getElementById('editNameModal'));
      modal.hide();
    } else {
      alert('Errore nell\'aggiornamento del nome');
    }
  })
  .catch(error => {
    console.error('Errore:', error);
  });
});