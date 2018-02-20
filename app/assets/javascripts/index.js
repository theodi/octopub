$( document ).ready(function() {
  var rowCount = function(id) {
    return $("id > tbody").children.length
  };

  $('#data-count').append(rowCount('#home-table-data'));
  $('#schema-count').append(rowCount('#schema-table-data'));
});
