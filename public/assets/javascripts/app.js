$(function() {
  $("#form").submit(function(e) {
    var domain;
    e.preventDefault();
    domain = $("#domain").val();
    document.location = "/domains/" + domain;
    return false;
  });
});
