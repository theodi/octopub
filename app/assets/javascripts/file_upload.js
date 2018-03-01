"use strict";

$(document).ready(function() {

  if ($('div.file-panel').length) {
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

  function addAnotherDataFileButtonClick() {
    var file = $('div.file-panel:first').clone();

    // Clone button to create another file to upload
    $('#clone').click(function(e) {
      e.preventDefault();
      var clone = $(file).clone();
      var timestamp = new Date().getTime();

      // Remove the error labels from the cloned inputs else they will have duplicates
      clone.find('label.error').remove()
      // Generate unique ids for the cloned inputs
      clone.find(':input').not(':button').not("[aria-label='Search']").each(function() {
        if (this.id) {
          this.id = this.id + timestamp
        }
      })

      // Add delete file button
      var buttonAndSpan = $('<span class="pull-right"><button type="button" class="btn btn-danger btn-xs">Delete file</button></span>');
      clone.find('div[name="data_file_heading"]').append(buttonAndSpan);
      buttonAndSpan.click(function(event) {
        var parentSection = $(event.target).closest('div.file-panel');
        parentSection.remove();
      });

      // Append the cloned inputs and attach file uploader listeners
      clone.appendTo('#files');
      clone.find('.bg-upload').each(function(i, elem) {
        bgUpload(elem);
      });

      // Add validation rules (Jquery Validate)
      stepInputs("#step-three").each(function () {
        $(this).rules("add", {
          required: true
        });
      });

      // Update all select boxes to create rich search boxes
      $('.selectpicker').selectpicker('refresh');
    });
  }

  function addAjaxFormUploading() {
   // Do ajax form uploading
    $('form').submit(function(e) {
      e.preventDefault();

      $('#spinner').removeClass('hidden');

      if (($('.s3-file').length > 0) || $('form').hasClass('edit-form')) {
        postForm($(this));
      } else {
        // $('body').scrollTop(0);
        // addError('You must add at least one file');
        $('#spinner').addClass('hidden');
      }

    });
  }

  function setUpCloneAndFileUpload() {
    addAnotherDataFileButtonClick();
    addAjaxFormUploading();
    setUpFileUpload();
  }

  // ###################################### Validation Code ######################################

  // Initialise Jquery Validate on form
  var validator = $('#add-dataset-form').validate({
    rules: { // Validation rules (inputs are identified by name attribute)
      'dataset[name]': { required: true },
      'dataset[description]': { required: true },
      'dataset[frequency]': { required: true },
      'dataset[license]': { required: true },
      'files[][title]': { required: true },
      'files[][description]': { required: true },
      '[files[][file]]': { required: true },
      '_files[][dataset_file_schema_id]': { required: true }
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
      console.log(stepsToValidate(targetStep))

      if (stepsValid(stepsToValidate(targetStep))) {
        hideCurrentStep()
        showTargetStep(targetStep)
        $('#wizard-breadcrumb').find(targetStepButton).attr('disabled', false)
        currentStep = targetStep
      }
      e.preventDefault()
    })
  })

  // Get the steps that require validation inbetween currentStep and targetStep
  // Accepts string e.g. 'step-three'
  // Returns array of steps e.g. ['step-one', 'step-two']
  function stepsToValidate(targetStep) {
    var currentStepIndex = formSteps.indexOf(currentStep)
    var targetStepIndex = formSteps.indexOf(targetStep)
    var steps = []

    if (targetStepIndex > currentStepIndex) {
      for (var i = currentStepIndex; i < targetStepIndex; i++) {
        steps.push(formSteps[i])
      }
    }
    return steps
  }

  // Validate steps and returns true if all passed-in steps are valid, false otherwise
  // Accepts array of strings e.g. ['step-one', 'step-two']
  // Returns boolean
  function stepsValid(steps) {
    if (!steps.length) { return true }

    // This builds an array of booleans, each one representing the validity of a step
    // Then it sums the booleans to get the validity of all steps combined
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

  // Get the inputs for a step
  // Accepts string e.g. 'step-one'
  // Returns JQuery object
  function stepInputs(step) {
    // Return all step inputs except buttons and search boxes for dropdowns
    return $(step).find(':input').not(':button', "[aria-label='Search']")
  }

  function hideCurrentStep() {
    $('#' + currentStep).addClass('hidden')
  }

  function showTargetStep(selector) {
    $('#' + selector).removeClass('hidden')
  }

  // Override Jquery Validate checkForm function to allow validation of array inputs with same name
  // This is neccessary for the file and schema inputs
  $.validator.prototype.checkForm = function() {
    this.prepareForm();
    for (var i = 0, elements = (this.currentElements = this.elements()); elements[i]; i++) {
      if (this.findByName(elements[i].name).length !== undefined && this.findByName(elements[i].name).length > 1) {
        for (var cnt = 0; cnt < this.findByName(elements[i].name).length; cnt++) {
          this.check(this.findByName(elements[i].name)[cnt]);
        }
      } else {
        this.check(elements[i]);
      }
    }
    return this.valid();
  };

});