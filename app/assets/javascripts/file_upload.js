"use strict";

$(document).ready(function() {

  if ($('div.file-input-group').length) {
    setUpCloneAndFileUpload();
  }
  if ($('div.schema-panel').length) {
    setUpFileUpload();
  }

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
        var url   = 'https://' + form.data('host') + '/' + encodeURI(key);

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
    var formMethod = $('input:hidden[name=_method]').val() || 'post'
    var channelID = formMethod + '-' +  uuid();
    console.log("Pusher channelID: " + channelID);

    $.ajax({
      type: formMethod,
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
        window.location = '/datasets/created?publishing_method=' + data.publishing_method;
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

  function setUpFileUpload() {
    $('.bg-upload').each(function(i, elem) {
      bgUpload(elem);
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

  var currentInputGroup = $('.file-input-group:first')
  var inputGroup = currentInputGroup.clone()

  function addAnotherDataFileButtonClick() {
    // Clone button to create another file to upload
    $('#clone').click(function(e) {
      if (form.valid()) {
        hideStepDescription(currentStep)
        var newInputGroup = $(inputGroup).clone().removeClass('hidden')
        var timestamp = new Date().getTime()

        // Remove the error labels from the cloned inputs else they will have duplicates
        newInputGroup.find('label.error').remove()
        newInputGroup.find(':input').not(':button').not("[aria-label='Search']").each(function() {
          if (this.id) {
            $(this).val('') // Empty the input values
            this.id = this.id + timestamp // Generate a unique input id
          }
        })

        // give the input group a unique data-id
        if ( ! currentInputGroup.attr('data-complete')) {
          currentInputGroup.attr('data-complete', true)
          makeSidebarLinks(currentInputGroup)
        }

        // Append the input group and attach file uploader listeners
        newInputGroup.appendTo('#files');
        newInputGroup.find('.bg-upload').each(function(i, elem) {
          bgUpload(elem);
        });

        // activate bootstrap tooltips
        $('body').tooltip({
          selector: '[data-toggle="tooltip"]'
        });


        $('.file-input-group').hide()
        newInputGroup.fadeIn()
        updateCurrentInputGroup(newInputGroup)

        // Update all select boxes to create rich search boxes
        $('.selectpicker').selectpicker('refresh');
        e.preventDefault()
      }
    });
  }

  var sidebarLinks = $('#sidebar-links').find('li:first').clone(true)

  function makeSidebarLinks(inputGroup) {
    var links = sidebarLinks.clone(true)

    if ($('.file-input-group').length > 1) {
      var deleteLink = "<a href='#' class='delete'><i class='fa fa-trash-alt'></i> Delete</a>"
      links.find('.sidebar-file-links').append(deleteLink)
    }

    $('.sidebar-files').append(links).hide().fadeIn()

    links.find('.edit').click(function(event){
      $('.file-input-group').hide()
      $('.file-input-group:not([data-complete])').remove()
      inputGroup.fadeIn()
      updateCurrentInputGroup(inputGroup)
      event.preventDefault()
    })

    links.find('.delete').click(function(event){
      if (inputGroup === currentInputGroup) {
        inputGroup.prev().fadeIn()
      }
      inputGroup.remove()
      links.remove()
      event.preventDefault()
    })

    var fileTitle = inputGroup.find('[name="files[][title]"]').first().val()
    var schemaName = inputGroup.find('[name="[files[][dataset_file_schema_id]]"] option:selected').text()

    var fileSize
    if (window.FileReader) {
      var file = inputGroup.find('input[type="file"]')[0].files[0]
      fileSize = toMegabytes(file.size) + 'MB'
    }

    var sidebarFileDetails = fileSize ? `${fileTitle} (${fileSize})` : fileTitle
    links.find('.sidebar-file-details').text(sidebarFileDetails)
    links.find('.sidebar-schema-details').text(schemaName)

    inputGroup.find('[name="files[][title]"]').change(function(){
      var fileTitle = inputGroup.find('[name="files[][title]"]').first().val()
      var fileSize
      if (window.FileReader) {
        var file = inputGroup.find('input[type="file"]')[0].files[0]
        fileSize = toMegabytes(file.size) + 'MB'
      }
      var sidebarFileDetails = fileSize ? `${fileTitle} (${fileSize})` : fileTitle
      links.find('.sidebar-file-details').text(sidebarFileDetails)
    })

    inputGroup.find('[name="[files[][file]]"]').change(function(){
      var fileTitle = inputGroup.find('[name="files[][title]"]').first().val()
      var fileSize
      if (window.FileReader) {
        var file = inputGroup.find('input[type="file"]')[0].files[0]
        console.log(file)
        fileSize = toMegabytes(file.size) + 'MB'
      }
      var sidebarFileDetails = fileSize ? `${fileTitle} (${fileSize})` : fileTitle
      links.find('.sidebar-file-details').text(sidebarFileDetails)
      form.validate()
    })

    inputGroup.find('[name="[files[][dataset_file_schema_id]]"]').change(function(){
      var schemaName = inputGroup.find('[name="[files[][dataset_file_schema_id]]"] option:selected').text()
      links.find('.sidebar-schema-details').text(schemaName)
    })
  }

  function updateCurrentInputGroup(inputGroup) {
    currentInputGroup = inputGroup
  }

  function toMegabytes(bytes) {
    return bytes/1000000
  }

  if ($('[name="dataset[name]"]').val()) { $('#chosen-folder').text($('[name="dataset[name]"]').val()) }
  if ($('[name="dataset[frequency]"]').find('option:selected').text()) { $('#chosen-frequency').text($('[name="dataset[frequency]"]').find('option:selected').text()) }
  if ($('[name="dataset[license]"]').find('option:selected').text()) { $('#chosen-licence').text($('[name="dataset[license]"]').find('option:selected').text()) }

  $('[name="dataset[name]"]').change(function(){
    $('#chosen-folder').text($(this).val())
  })

  $('[name="dataset[frequency]"]').change(function(){
    $('#chosen-frequency').text($(this).find('option:selected').text())
  })

  $('[name="dataset[license]"]').change(function(){
    $('#chosen-licence').text($(this).find('option:selected').text())
  })

  $('[name="[files[][file]]"]').change(function(){
    $(this).blur().focus();
  })

  function addAjaxFormUploading() {
   // Do ajax form uploading
    $('form').submit(function(e) {
      e.preventDefault();

      $('#spinner').removeClass('hidden');

      console.log(form.valid())

      if (form.valid()) {
        console.log('post form yeaaaaah!')
        postForm($(this));
      }

      // if (($('.s3-file').length > 0) || $('form').hasClass('edit-form')) {
      //   console.log('post form! yeeeeah!')
      //   postForm($(this));
      // } else {
      //   $('#spinner').addClass('hidden');
      // }

    });
  }

  function setUpCloneAndFileUpload() {
    addAnotherDataFileButtonClick();
    addAjaxFormUploading();
    setUpFileUpload();
  }

  // ###################################### Validation Code ######################################

  // Initialise Jquery Validate on form
  var form = $('#add-dataset-form')
  var validator = form.validate({
    ignore: [],
    rules: { // Validation rules (inputs are identified by name attribute)
      'dataset[name]': { required: true },
      'dataset[description]': { required: true },
      'dataset[frequency]': { required: true },
      'dataset[license]': { required: true },
      'files[][title]': { required: true },
      'files[][description]': {},
      '[files[][file]]': { required: true, alphanum_filename: true },
      '[files[][dataset_file_schema_id]]': {}
    },
    onfocusout: function(element) {
      this.element(element) // Validate elements on onfocusout
    }
  });

  var formSteps = ['step-one', 'step-two', 'step-three']
  var currentStep = formSteps[0]

  // Setup click handlers for step navigation buttons
  $.each(formSteps, function(i, targetStep) {
    var targetStepButton = '.show-' + targetStep

    $(document).on('click', targetStepButton, function (e) {
      if (stepsValid(stepsToValidate(targetStep))) {
        hideCurrentStep()
        showTargetStep(targetStep)
        if (currentStep === formSteps[0] || currentStep === formSteps[1]) {
          hideStepDescription(currentStep)
        }
        currentStep = targetStep
      }
      e.preventDefault()
    })
  })

  function hideStepDescription(step) {
    $('.show-' + step).parents('.wizard-sidebar-step').find('.wizard-sidebar-step-description').hide();
  }

  // Get the steps that require validation inbetween currentStep and targetStep
  // Accepts string e.g. 'step-three'
  // Returns array of steps e.g. ['step-one', 'step-two']
  function stepsToValidate(targetStep) {
    return formSteps.slice(formSteps.indexOf(currentStep), formSteps.indexOf(targetStep))
  }

  // Returns true if all passed-in steps are valid, false otherwise
  // Accepts array of strings e.g. ['step-one', 'step-two']
  function stepsValid(steps) {
    if (!steps.length) { return true }

    // This builds an array of booleans, each one representing the validity of a step
    // Then it sums the booleans to get the total validity of the steps
    return steps.map(function(step) {   
      return stepValid(step)
    }).reduce(function(sum, bool) {
      return sum && bool
    })
  }

  // Return true if step is valid, false otherwise
  // Accepts string e.g. 'step-one'
  function stepValid(step) {
    // .valid() is a JQuery Validate function
    return stepInputs('#' + step).valid()
  }

  // Return the inputs for a step as a JQuery Object
  // Accepts string e.g. '#step-one'
  function stepInputs(step) {
    // Return all step inputs except buttons and search boxes for dropdowns
    return $(step).find(':input').not(':button').not("[aria-label='Search']")
  }

  function hideCurrentStep() {
    $('#' + currentStep).addClass('hidden')
    var step = $('.show-' + currentStep).parents('.wizard-sidebar-step')
      step.removeClass('wizard-sidebar-step-active wizard-sidebar-step-inactive wizard-sidebar-step-disabled')
      .addClass('wizard-sidebar-step-inactive')
  }

  function showTargetStep(targetStep) {
    $('#' + targetStep).fadeIn().removeClass('hidden')
    $.each(stepsToValidate(targetStep), function(i, step) {
      $('.show-' + step).parents('.wizard-sidebar-step')
        .removeClass('wizard-sidebar-step-active wizard-sidebar-step-inactive wizard-sidebar-step-disabled')
        .addClass('wizard-sidebar-step-inactive')
    })
    $('.show-' + targetStep).parents('.wizard-sidebar-step')
        .removeClass('wizard-sidebar-step-active wizard-sidebar-step-inactive wizard-sidebar-step-disabled')
        .addClass('wizard-sidebar-step-active')
  }

  // Override Jquery Validate checkForm function to allow validation of array inputs with same name
  // This is neccessary for the file and schema inputs
  $.validator.prototype.checkForm = function() {
    this.prepareForm();
    for (var i = 0, elements = (this.currentElements = this.elements()); elements[i]; i++) {
      if (this.findByName(elements[i].name).length !== undefined && this.findByName(elements[i].name).length > 1) {
        for (var cnt = 0; cnt < this.findByName(elements[i].name).length; cnt++) {
          this.check(this.findByName(elementss[i].name)[cnt]);
        }
      } else {
        this.check(elements[i]);
      }
    }
    return this.valid();
  };

  $.validator.addMethod('alphanum_filename', function(value, element) {
      // param = size (in bytes) 
      // element = element to validate (<input>)
      // value = value of the element (file name)
      var fileName = element.files[0].name
      console.log(fileName.substring(0, fileName.lastIndexOf('.')))
      return this.optional(element) || (/^\w+$/i.test(fileName.substring(0, fileName.lastIndexOf('.'))))
  }, "File name must only contain letters, numbers, and underscores");

});