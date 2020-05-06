$(document).ready(function() {
	// Count the number of rows in a table
  var rowCount = function(id) {
    string = id + " tbody tr"
    return $(string).length
  };

	// Count table rows using the rowCount function
  $('#data-count').append(rowCount('#home-table-data'));
  $('#schema-count').append(rowCount('#schema-table-data'));

	// Alter Bootstrap table messages
	$('.no-records-found td').html('Once you have uploaded a file it will appear here.')
});
