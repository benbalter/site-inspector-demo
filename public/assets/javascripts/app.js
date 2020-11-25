var form = document.getElementById('form');
form.addEventListener('submit', function(event) {
  event.preventDefault();
  domain = document.getElementById('domain').value
  document.location = "/domains/" + domain;
  return false;
});