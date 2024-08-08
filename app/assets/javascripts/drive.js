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
    $.ajax({
      url: '/items/' + itemId + '/properties',
      type: 'GET',
      dataType: 'json',
      success: function(data){
        // Populate the modal with the file details
        $('#file-name').text("Nome: " + data.name);
        $('#file-mime_type').text("Tipo di file: " + data.mime_type);
        $('#file-size').text("Dimensione: " + get_file_size(data.size));
        $('#file-created_time').text("Data di creazione: " + new Date(data.created_time).toLocaleString());
        $('#file-modified_time').text("Data di modifica: " + new Date(data.modified_time).toLocaleString());
        
        var ownersText = data.owners.map(owner => owner.display_name + " (" + owner.email + ")").join(", ");
        $('#file-owners').text("Owners: " + ownersText);
        
        var permissionsText = data.permissions.map(permission => {
          return permission.role + " (" + permission.type + ")";
        }).join(", ");
        
        $('#file-permissions').text("Permissions: " + permissionsText);
        $('#file-shared').text("Shared: " + (data.shared ? "Yes" : "No"));

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
      method: 'GET',
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
function handleExportAsPDF() {
  document.querySelectorAll('.export-item').forEach(item => {
    item.addEventListener('click', function(event) {
      event.preventDefault();
      apri_modal('md_export');
      const fileId = this.getAttribute('data-id');
      const type = this.getAttribute('type');

      console.log('File ID:', fileId);
      console.log('Type:', type);

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
        console.error('Error:', error);
        alert('Si è verificato un errore durante la conversione del file.');
      });
    });
  });
}


//export folder
document.querySelectorAll('.export-folder').forEach(item => {
  item.addEventListener('click', function(event) {
    event.preventDefault();
    alert("DA IMPLEMENTARE");
  });
});

$(document).ready(function() {
  $('.dropdown-submenu > a').on('click', function(e) {
    e.stopPropagation();
    e.preventDefault();

    const fileId = this.getAttribute('data-id');
    const $submenu = $(this).next('.submenu');

    // Funzione per aggiornare il sottomenu
    const updateSubmenu = (ext) => {
      //si aggiungono i tasti per le conversioni dei vari file
      switch(ext){
        case 'vnd.openxmlformats-officedocument.wordprocessingml.document': 
          $submenu.html(
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="SELF">DOCX</a></li>' +
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PDF">PDF</a></li>'
          );
        case 'vnd.oasis.opendocument.text':
          $submenu.html(
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="SELF">ODT</a></li>' +
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="DOCX">DOCX</a></li>'+
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PDF">PDF</a></li>'
          );
          break;
        case 'vnd.openxmlformats-officedocument.spreadsheetml.sheet':
          $submenu.html(
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="SELF">XLSX</a></li>' +
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PDF">PDF</a></li>'
          );
          break;

        case 'vnd.oasis.opendocument.spreadsheet':
          $submenu.html(
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="SELF">ODS</a></li>' +
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="XLSX">XLSX</a></li>'+
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PDF">PDF</a></li>'
          );
          break;
        case 'vnd.openxmlformats-officedocument.presentationml.presentation':
          $submenu.html(
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="SELF">PPTX</a></li>' +
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PDF">PDF</a></li>'
          );
          break;
        case 'vnd.oasis.opendocument.presentation':
          $submenu.html(
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="SELF">ODP</a></li>' +
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PPTX">PPTX</a></li>'+
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PDF">PDF</a></li>'
          );
          break;
        case 'png':
          $submenu.html(
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="SELF">PNG</a></li>' +
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="jpeg">JPEG</a></li>'+
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PDF">PDF</a></li>'
          );
          break;
        case 'jpeg':
          $submenu.html(
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="SELF">JPEG</a></li>' +
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PNG">PNG</a></li>'+
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="PDF">PDF</a></li>'
          );
          break;
        default:
          $submenu.html(
            '<li><a href="javascript:void(0);" class="dropdown-item export-item" data-id="'+ fileId +'" data-folder-id="<%= @current_folder %>" type="SELF">'+ext+'</a></li>'
          );
          break;
      }
      handleExportAsPDF();
      // Mostra e posiziona il sottomenu solo dopo che è stato aggiornato
      $('.dropdown-submenu .submenu').not($submenu).hide();
      $submenu.removeClass('submenu-left submenu-right');
      
      var submenuWidth = $submenu.outerWidth();
      var distanceToRight = $(window).width() - ($(this).offset().left + $(this).outerWidth());
      
      if (distanceToRight < submenuWidth) {
        $submenu.addClass('submenu-left');
      } else {
        $submenu.addClass('submenu-right');
      }

      var topPosition = $(this).position().top;
      $submenu.css('top', topPosition);
      $submenu.show();
    };

    fetch('/extension?id=' + fileId)
      .then(response => response.json())
      .then(data => {
        const ext = data.type.split('/')[1];
        console.log(ext);
        updateSubmenu(ext);
      })
      .catch(error => {
        console.error('Error:', error);
        updateSubmenu(null);
      });
  });

  $('.dropdown').on('hidden.bs.dropdown', function () {
    $('.dropdown-submenu .submenu').hide();
  });

  $(document).on('click', function (e) {
    if (!$(e.target).closest('.dropdown-submenu').length) {
      $('.dropdown-submenu .submenu').hide();
    }
  });
});



