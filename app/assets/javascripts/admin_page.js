// JavaScript per gestire l'apertura del modal e il riempimento del campo user_id
document.addEventListener('DOMContentLoaded', () => {
  // Aggiungi un evento click a tutti i pulsanti con la classe 'suspend-user-btn'
  document.querySelectorAll('.suspend-user-btn').forEach(button => {
    button.addEventListener('click', function() {
      // Ottieni l'ID dell'utente dal data attribute del bottone
      const userId = this.getAttribute('data-user-id');
      // Imposta il valore dell'input hidden nel modal
      document.getElementById('modalUserId').value = userId;
    });
  });

  // Gestione dell'invio del modulo di sospensione
  document.getElementById('suspendForm').addEventListener('submit', function(event) {
    event.preventDefault(); // Evita il comportamento predefinito del form

    const userId = document.getElementById('modalUserId').value;
    const days = document.getElementById('days').value;

    // Invio del modulo tramite fetch API
    fetch(`/admin/suspend_user/${userId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('input[name="authenticity_token"]').value
      },
      body: JSON.stringify({ days: days })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {

        location.reload(); // Ricarica la pagina per aggiornare lo stato dell'utente
      } else {
        alert('There was an error suspending the user.');
      }
    })
    .catch(error => console.error('Error:', error));
  });
});
