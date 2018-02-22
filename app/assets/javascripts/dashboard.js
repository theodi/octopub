"use strict";

$(document).ready(function() {

  // Search input for the dashboard
  // Search occurs upon keydown on 'Enter'
  $("#myInput").on("keydown", function(e) {
    var value = $(this).val().toLowerCase();
    if(e.which === 13){
      $("#myTable tr").filter(function() {
        $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
      });
    }
  });

  // Clearing the search input and reseting the dashboard
  $(".hasclear").keyup(function () {
    var t = $(this);
    t.next('span').toggle(Boolean(t.val()));
  });

  $(".clearer").hide($(this).prev('input').val());

  $(".clearer").click(function (event) {
    $(this).prev('input').val('').focus();
    $(this).hide();
    var e = $.Event('keydown');
    e.which = 13;
    $('input').trigger(e);
  });

  if ($('#refresh').length) {
    var pusher = setUpPusher();

    $('a#refresh').click(function(e) {

      var currentUserId = $('a#refresh').data('user-id');
      var channelID = 'datasetRefresh-' + currentUserId;
      var spinner = $(this).find('.fa-refresh');

      spinner.addClass('fa-spin');

      $.get('/datasets/refresh?channel_id=' + channelID, function() {
        var channel = pusher.subscribe(channelID);
        channel.bind('refreshed', function(data) {
          spinner.removeClass('fa-spin');
          location.reload();
        });
      }).fail(function(e) {
        console.log('Pusher refresh failure');
        console.log(e);
      });

      e.preventDefault();
    });
  }
});
