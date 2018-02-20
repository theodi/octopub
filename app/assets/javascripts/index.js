$(document).ready(function() {
  var rowCount = function(id) {
    string = id + " tbody tr"
    return $(string).length
  };

  $('#data-count').append(rowCount('#home-table-data'));
  $('#schema-count').append(rowCount('#schema-table-data'));
});
