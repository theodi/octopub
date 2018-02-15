"use strict";

$(document).ready(function() {

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
