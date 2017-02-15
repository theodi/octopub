"use strict";

function bgUpload(elem) {
  var container    = $(elem);
  var fileInput    = $(elem).find('input[type="file"]');
  var form         = $(fileInput.parents('form:first'));
  var submitButton = form.find('button[type="submit"]');
  var progressBar  = $("<div class='progress-bar progress-bar-success progress-bar-striped active' role='progressbar' aria-valuenow='0' aria-valuemin='0' aria-valuemax='100'></div>");
  var barContainer = $("<div class='progress hidden'></div>").append(progressBar);
  fileInput.after(barContainer);
  fileInput.fileupload({
    fileInput:       fileInput,
    url:             form.data('url'),
    type:            'POST',
    autoUpload:       true,
    formData:         form.data('form-data'),
    paramName:        'file', // S3 does not like nested name fields i.e. name="user[avatar_url]"
    dataType:         'XML',  // S3 returns XML if success_action_status is set to 201
    replaceFileInput: false,
    progressall: function (e, data) {
      var progress = parseInt(data.loaded / data.total * 100, 10);
      progressBar.css('width', progress + '%');
      progressBar.attr('aria-valuenow', progress);
      progressBar.text(progress + '%');
    },
    start: function (e) {
      submitButton.prop('disabled', true);

      barContainer.removeClass('hidden');

      // Remove existing hidden fields
      container.find('.s3-file').remove();

      progressBar.css('width', '0%');
    },
    done: function(e, data) {
      submitButton.prop('disabled', false);
      progressBar.text("Done");
      progressBar.removeClass('active');
      // extract key and generate URL from response
      var key   = $(data.jqXHR.responseXML).find("Key").text();
      var url   = 'https://' + form.data('host') + '/' + key;

      // create hidden field
      var input = $("<input />", { type:'hidden', name: fileInput.attr('name'), value: url, class: 's3-file' });
      container.append(input);
    },
    fail: function(e, data) {
      submitButton.prop('disabled', false);
      progressBar.removeClass('progress-bar-success');
      progressBar.addClass('progress-bar-danger');

      progressBar.
        css("background", "red").
        text("Upload Failed");
    }
  });
}

function postForm(form) {
  var channelID = form.attr('method') + '-' +  uuid();
  console.log("Pusher channelID: " + channelID);

  $.ajax({
    type: form.attr('method'),
    url: form.attr('action'),
    data: form.serialize() + '&async=true&channel_id=' + channelID,
    success: bindToPusher(channelID)
  });
}

function bindToPusher(channelID) {
  var pusher = setUpPusher();
  var channel = pusher.subscribe(channelID);

  channel.bind('dataset_created', function(data) {
    if (channelID.match(/post/)) {
      window.location = '/datasets/created';
    } else {
      window.location = '/datasets/edited';
    }
  });
  channel.bind('dataset_failed', function(data) {
    addErrors(data);
  });
}

function addErrors(data) {
  $('#spinner').addClass('hidden');
  $('body').scrollTop(0);
  $(data).each(function(i, message) {
    addError(message);
  });

  $('.bg-upload').each(function(i, elem) {
    bgUpload(elem);
  });

  // Destroy any existing progress bars
  $('.progress').addClass('hidden');
}

function addError(message) {
  alert = $('<div class="alert alert-danger" role="alert">').text(message);
  $('#main').prepend(alert);
}

function setUpCloneAndFileUpload() {
  var file = $('div.file-panel:first').clone();

  // Clone button to create another file to upload
  $('#clone').click(function(e) {

    e.preventDefault();
    var clone = $(file).clone();
    clone.find('.title').attr('required', 'required');
    clone.appendTo('#files');
    clone.find('.bg-upload').each(function(i, elem) {
      bgUpload(elem);
    });
  });

  $('.bg-upload').each(function(i, elem) {
    bgUpload(elem);
  });

  $('form').submit(function(e) {
    $('#spinner').removeClass('hidden');

    if (($('.s3-file').length > 0) || $('form').hasClass('edit-form')) {
      postForm($(this));
    } else {
      $('body').scrollTop(0);
      addError('You must add at least one file');
      $('#spinner').addClass('hidden');
    }

    e.preventDefault();
  });

  $('input.change-file').on('click', function(e) {
    $(this).attr('style', 'color:red');
    e.stopImmediatePropagation();

    var container = $(this).parents('.file');

    container.find('.current-file').addClass('hidden');
    container.find('.filename-wrapper').append('<div class="form-group"><label class="control-label" for="files[][file]">File</label><input class="bg-upload" id="_files[][file]" label="File" name="[files[][file]]" type="file" accept=".csv" /></div>');
    bgUpload(container);
  });
}

$(document).ready(function() {
  if ($('div.file-panel').length) {
    setUpCloneAndFileUpload();
  }
});

