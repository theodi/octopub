"use strict"

$(document).ready(function() {

  var s = {
    $form                         : $('form'),
    $files                        : $('.bg-upload'),
    $currentVisibleFileInputGroup : $('div.file-input-group:first'),
    $fileInputGroup               : $('div.file-input-group:first').clone(),
    $newFileInputGroup            : null
  }

  init()

  function init() {
    bindEvents()
    initFileUploads()
  }

  function bindEvents() {
    bindAddFileEvent()
    bindPostFormEvent()
    bindChangeFileEvent()
  }

  function initFileUploads() {
    s.$files.each(function(i, elem) {
      initFileUpload(elem)
    })
  }

  function bindChangeFileEvent() {
    $('.change-file').on('click', function(e) {
      e.preventDefault()
      var container = $(this).parents('.file')

      container.find('.current-file').addClass('hidden')
      container.find('.filename-wrapper').append('<div class="form-group"><label class="control-label" for="files[][file]">Files</label><input class="bg-upload" id="_files[][file]" label="File" name="[files[][file]]" type="file" /></div>')
      initFileUpload(container)
    });
  }

  function initFileUpload(elem) {
    var container            = $(elem)
    var fileInput            = $(elem).find('input[type="file"]')
    var form                 = $(fileInput.parents('form:first'))
    var submitButton         = form.find('button[type="submit"]')
    var progressBar          = $("<div class='progress-bar progress-bar-success progress-bar-striped active' role='progressbar' aria-valuenow='0' aria-valuemin='0' aria-valuemax='100'></div>")
    var progressBarContainer = $("<div class='progress hidden'></div>")

    progressBarContainer.append(progressBar)
    fileInput.after(progressBarContainer)

    // Plugin: https://github.com/blueimp/jQuery-File-Upload
    fileInput.fileupload({
      fileInput:       fileInput,
      url:             form.data('url'),
      type:            'POST',
      autoUpload:       true,
      formData:         form.data('form-data'),
      paramName:        'file', // S3 does not like nested name fields i.e. name="user[avatar_url]"
      dataType:         'XML',  // S3 returns XML if success_action_status is set to 201
      replaceFileInput: false,
      progressall: function(e, data) {
        var progress = parseInt(data.loaded / data.total * 100, 10)
        progressBar.css('width', progress + '%')
        progressBar.attr('aria-valuenow', progress)
        progressBar.text(progress + '%')
      },
      start: function(e) {
        submitButton.prop('disabled', true)
        progressBarContainer.removeClass('hidden')
        // Remove existing hidden fields
        container.find('.s3-file').remove()
        progressBar.css('width', '0%')
      },
      done: function(e, data) {
        submitButton.prop('disabled', false)
        progressBar.text("Done")
        progressBar.removeClass('active')

        var key = $(data.jqXHR.responseXML).find("Key").text()
        var url = 'https://' + form.data('host') + '/' + encodeURI(key)
        // Create hidden field
        var input = $("<input />", { type:'hidden', name: fileInput.attr('name'), value: url, class: 's3-file' })
        container.append(input)
      },
      fail: function(e, data) {
        submitButton.prop('disabled', false)
        progressBar.removeClass('progress-bar-success')
        progressBar.addClass('progress-bar-danger')
        progressBar.css("background", "red").text("Upload Failed")
      }
    })
  }

  function postForm(form) {
    var formMethod = $('input:hidden[name=_method]').val() || 'post'
    var channelID = formMethod + '-' +  uuid()
    console.log("Pusher channelID: " + channelID)

    $.ajax({
      type: formMethod,
      url: form.attr('action'),
      data: form.serialize() + '&async=true&channel_id=' + channelID,
      success: bindToPusher(channelID)
    })
  }

  function bindToPusher(channelID) {
    var pusher = setUpPusher()
    var channel = pusher.subscribe(channelID)

    channel.bind('dataset_created', function(data) {
      if (channelID.match(/post/)) {
        window.location = '/datasets/created?publishing_method=' + data.publishing_method
      } else {
        window.location = '/datasets/edited'
      }
    })
    channel.bind('dataset_failed', function(data) {
      addErrors(data)
    })
  }

  function addErrors(data) {
    $('#spinner').addClass('hidden')
    $('body').scrollTop(0)
    $(data).each(function(i, message) {
      addError(message)
    })
    initFileUploads()
    // Destroy any existing progress bars
    $('.progress').addClass('hidden')
  }

  function addError(message) {
    var alert = $('<div class="alert alert-danger" role="alert">').text(message)
    $('#main').prepend(alert)
  }

  function newFileInputGroup() {
    var newFileInputGroup = $(s.$fileInputGroup).clone()
    // Iterate over the inputs of the file input group
    newFileInputGroup.find(':input').not(':button').not("[aria-label='Search']").each(function() {
      if (this.id) {
        $(this)
        	.attr('disabled', false)
    		.attr('readonly', false)
        // Make input id's unique so Jquery Validate works correctly
        this.id = this.id + new Date().getTime()
      }
    })
    // newFileInputGroup.append("<button class='btn btn-lg btn-danger delete'>delete</button>")
    // newFileInputGroup.find('.delete').click(function(e) {
    //   e.preventDefault()
    //   var nearest = nearestFileInputGroup(newFileInputGroup)
    //   nearest.show()
    //   s.$currentVisibleFileInputGroup = nearest
    //   newFileInputGroup.remove()
    // })
    return newFileInputGroup
  }

  function bindAddFileEvent() {
    $('#clone').click(function(e) {
      e.preventDefault()
      // Only add new file inputs if the current form is valid
      if (s.$form.valid()) {
      	console.log('addit')
        // Create new file input group
        s.$newFileInputGroup = newFileInputGroup()
        // Append new file input group to DOM
        s.$newFileInputGroup.appendTo('#files').hide().fadeIn()
        // Attach file upload listeners
        s.$newFileInputGroup.find('.bg-upload').each(function(i, elem) {
          initFileUpload(elem)
        })
        reloadTooltips()
      } else {
      	console.log('potate')
      }
    })
  }

  function bindDeleteFileEvent() {
    $('#delete').click(function(e) {
      e.preventDefault()
      var nearest = nearestFileInputGroup(newFileInputGroup)
      s.$currentVisibleFileInputGroup.remove()
      s.$currentVisibleFileInputGroup = nearest
      nearest.show()
    })
  }

  function reloadTooltips() {
    $('body').tooltip({
      selector: '[data-toggle="tooltip"]'
    })
  }

  function bindPostFormEvent() {
    s.$form.submit(function(e) {
      e.preventDefault()
      if (s.$form.valid() && ($('.s3-file').length > 0) || s.$form.hasClass('edit-form')) {
        postForm($(this))
        $('#spinner').removeClass('hidden')
        $('button[type=submit]').attr('disabled', true)
      }
    })
  }

  // ###################################### Validation Code ######################################

  // Initialise Jquery Validate on form
  var validator = s.$form.validate({
    ignore: [],
    rules: { // Validation rules (inputs are identified by name attribute)
      // 'dataset[name]': { required: true },
      'dataset[description]': { required: true },
      'dataset[frequency]': { required: true },
      'dataset[license]': { required: true },
      // 'files[][title]': { required: true },
      'files[][description]': {},
      // '[files[][file]]': { required: true, alphanum_filename: true },
      '[files[][dataset_file_schema_id]]': {}
    },
    onfocusout: function(element) {
      this.element(element) // Validate elements on onfocusout
    }
  })

  // Override Jquery Validate checkForm function to allow validation of array inputs with same name
  // This is neccessary for the file and schema inputs
  $.validator.prototype.checkForm = function() {
    this.prepareForm()
    for (var i = 0, elements = (this.currentElements = this.elements()); elements[i]; i++) {
      if (this.findByName(elements[i].name).length !== undefined && this.findByName(elements[i].name).length > 1) {
        for (var cnt = 0; cnt < this.findByName(elements[i].name).length; cnt++) {
          this.check(this.findByName(elements[i].name)[cnt])
        }
      } else {
        this.check(elements[i])
      }
    }
    return this.valid()
  }

  // Add a validator to Jquery Validate for alphanumeric filenames
  $.validator.addMethod('alphanum_filename', function(value, element) {
    if (element.files) {
      var fileName = element.files[0].name
      return this.optional(element) || (/^[a-z\d\-_\s]+$/i.test(fileName.substring(0, fileName.lastIndexOf('.'))))
    } else {
      return true
    }
  }, 'File name must only contain letters, numbers, and underscores')

})