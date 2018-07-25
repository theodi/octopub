"use strict"

$(document).ready(function() {

  var s = {
    $form                         : $('form'),
    $files                        : $('.bg-upload'),
    $currentVisibleFileInputGroup : $('div.file-input-group:nth-child(2)'),
    $fileInputGroup               : $('div.file-input-group:first').clone(),
    $newFileInputGroup            : null,
    $sidebarLink                  : $('#sidebar-links').find('li:first').clone(),
    $wizardSidebarStepClasses     : 'wizard-sidebar-step-active wizard-sidebar-step-inactive wizard-sidebar-step-disabled',
    $datasetNameInput             : $('[name="dataset[name]"]'),
    $datasetFrequencyInput        : $('[name="dataset[frequency]"]'),
    $datasetLicenseInput          : $('[name="dataset[license]"]'),
    $datasetFileInputs            : $('[name="[files[][file]]"]'),
    $chosenFolder                 : $('#chosen-folder'),
    $chosenFrequency              : $('#chosen-frequency'),
    $chosenLicense                : $('#chosen-licence')
  }

  init()

  function init() {
    bindEvents()
    initFileUploads()
    loadSidebarValues()
  }

  function bindEvents() {
    bindAddFileEvent()
    bindPostFormEvent()
    bindInputChangeEvents()
  }

  function initFileUploads() {
    s.$files.each(function(i, elem) {
      initFileUpload(elem)
    })
  }

  function loadSidebarValues() {
    if (s.$datasetNameInput.val()) {
      s.$chosenFolder.text(s.$datasetNameInput.val())
    }
    if (s.$datasetFrequencyInput.find('option:selected').text()) {
      s.$chosenFrequency.text(s.$datasetFrequencyInput.find('option:selected').text())
    }
    if (s.$datasetLicenseInput.is(':checked')) {
       s.$chosenLicense.text($('[name="dataset[license]"]:checked').val())
    }
  }

  function bindInputChangeEvents() {
    s.$datasetNameInput.change(function(){
      s.$chosenFolder.text($(this).val())
    })
    s.$datasetFrequencyInput.change(function(){
      s.$chosenFrequency.text($(this).find('option:selected').text())
    })
    s.$datasetLicenseInput.change(function(){
      s.$chosenLicense.text($('[name="dataset[license]"]:checked').val())
    })
    s.$datasetFileInputs.change(function(){
      $(this).blur().focus()
    })
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
        // Make a sidebar link for the current input group
        if (hasSidebarLink(s.$currentVisibleFileInputGroup) !== true) {
          s.$currentVisibleFileInputGroup.attr('data-complete', true)
          makeSidebarLink(s.$currentVisibleFileInputGroup)
        }
        // Create new file input group
        s.$newFileInputGroup = newFileInputGroup()
        // Append new file input group to DOM
        s.$newFileInputGroup.appendTo('#files').hide().fadeIn()
        // Attach file upload listeners
        s.$newFileInputGroup.find('.bg-upload').each(function(i, elem) {
          initFileUpload(elem)
        })
        // Hide other file input groups
        s.$newFileInputGroup.siblings().hide()
        // Update the current visible input group
        s.$currentVisibleFileInputGroup = s.$newFileInputGroup
        hideStepDescription(currentStep)
        reloadTooltips()
      }
    })
  }

  // function bindDeleteFileEvent() {
  //   $('#delete').click(function(e) {
  //     e.preventDefault()
  //     var nearest = nearestFileInputGroup(newFileInputGroup)
  //     s.$currentVisibleFileInputGroup.remove()
  //     s.$currentVisibleFileInputGroup = nearest
  //     nearest.show()
  //   })
  // }

  function reloadTooltips() {
    $('body').tooltip({
      selector: '[data-toggle="tooltip"]'
    })
  }

  function hasSidebarLink(inputGroup) {
    return (inputGroup.attr('data-complete')) ? true : false
  }

  function makeSidebarLink(inputGroup) {
    var link = s.$sidebarLink.clone()
    $('.sidebar-files').append(link)
    bindSidebarLinkClickEvents(inputGroup, link)
    bindSidebarLinkChangeEvents(inputGroup, link)
  }

  function bindSidebarLinkClickEvents(inputGroup, link) {
    link.find('.edit').click(function(e){
      e.preventDefault()
      inputGroup.fadeIn().siblings().hide()
      s.$currentVisibleFileInputGroup = inputGroup
      if (s.$newFileInputGroup) { s.$newFileInputGroup.remove() }
    })

    link.find('.delete').click(function(e){
      e.preventDefault()
      // Must have at least one file input group
      if ($('.file-input-group[data-complete="true"]').length > 1) {
        if (inputGroup.is(s.$currentVisibleFileInputGroup)) {
          var nearest = nearestFileInputGroup(inputGroup)
          nearest.show()
          s.$currentVisibleFileInputGroup = nearest
        }
        inputGroup.remove()
        link.remove()
      } else {
        alert('Can\'t delete - At least one file is required')
      }
    })
  }

  function nearestFileInputGroup(inputGroup) {
    return (inputGroup.prev().length === 1 && inputGroup.prev('[data-complete="true"]').length === 1) ? inputGroup.prev() : inputGroup.next()
  }

  function bindSidebarLinkChangeEvents(inputGroup, link) {
    var fileTitle = inputGroup.find('[name="files[][title]"]').first().val()
    var schemaName = inputGroup.find('[name="[files[][dataset_file_schema_id]]"] option:selected').text()

    var fileSize
    if (window.FileReader) {
      var file = inputGroup.find('input[type="file"]')[0].files[0]
      fileSize = toMegabytes(file.size) + 'MB'
    }

    var sidebarFileDetails = fileSize ? `${fileTitle} (${fileSize})` : fileTitle
    link.find('.sidebar-file-details').text(sidebarFileDetails)
    link.find('.sidebar-schema-details').text(schemaName)

    inputGroup.find('[name="files[][title]"]').change(function(){
      var fileTitle = inputGroup.find('[name="files[][title]"]').first().val()
      var fileSize
      if (window.FileReader) {
        var file = inputGroup.find('input[type="file"]')[0].files[0]
        fileSize = toMegabytes(file.size) + 'MB'
      }
      var sidebarFileDetails = fileSize ? `${fileTitle} (${fileSize})` : fileTitle
      link.find('.sidebar-file-details').text(sidebarFileDetails)
    })

    inputGroup.find('[name="[files[][file]]"]').change(function(){
      var fileTitle = inputGroup.find('[name="files[][title]"]').first().val()
      var fileSize
      if (window.FileReader) {
        var file = inputGroup.find('input[type="file"]')[0].files[0]
        fileSize = toMegabytes(file.size) + 'MB'
      }
      var sidebarFileDetails = fileSize ? `${fileTitle} (${fileSize})` : fileTitle
      link.find('.sidebar-file-details').text(sidebarFileDetails)
    })

    inputGroup.find('[name="[files[][dataset_file_schema_id]]"]').change(function(){
      var schemaName = inputGroup.find('[name="[files[][dataset_file_schema_id]]"] option:selected').text()
      link.find('.sidebar-schema-details').text(schemaName)
    })
  }

  function toMegabytes(bytes) {
    return bytes/1000000
  }

  function bindPostFormEvent() {
    s.$form.submit(function(e) {
      e.preventDefault()
      if (s.$form.valid() && ($('.s3-file').length > 0 || s.$form.hasClass('edit-form'))) {
        console.log('postForm')
        postForm($(this))
        $('#spinner').removeClass('hidden')
        $('button[type=submit]').attr('disabled', true)
      } else {
        console.log(validator.errorList)
      }
    })
  }

  // ###################################### Validation Code ######################################

  // Initialise Jquery Validate on form
  var validator = s.$form.validate({
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
  })

  var formSteps = ['step-one', 'step-two', 'step-three']
  var currentStep = formSteps[0]

  // Setup click handlers for step navigation buttons
  $.each(formSteps, function(i, targetStep) {
    var targetStepButton = '.show-' + targetStep

    $(document).on('click', targetStepButton, function (e) {
      if (stepsValid(stepsToValidate(targetStep))) {
        hideStep(currentStep)
        showStep(targetStep)
        if (currentStep === formSteps[0] || currentStep === formSteps[1]) {
          hideStepDescription(currentStep)
        }
        currentStep = targetStep
      }
      e.preventDefault()
    })
  })

  function hideStepDescription(step) {
    getWizardSidebarStep(step).find('.wizard-sidebar-step-description').hide()
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

  function hideStep(step) {
    $('#' + step).addClass('hidden')
    deactivateSidebarStep(step)
  }

  function showStep(step) {
    $('#' + step).show().removeClass('hidden')
    $.each(stepsToValidate(step), function(i, s) { hideStep(s) })
    activateSidebarStep(step)
  }

  function deactivateSidebarStep(step) {
    getWizardSidebarStep(step)
      .removeClass(s.$wizardSidebarStepClasses)
      .addClass('wizard-sidebar-step-inactive')
  }

  function activateSidebarStep(step) {
    getWizardSidebarStep(step)
      .removeClass(s.$wizardSidebarStepClasses)
      .addClass('wizard-sidebar-step-active')
  }

  function getWizardSidebarStep(step) {
    return $('.show-' + step).parents('.wizard-sidebar-step')
  }

  $.fn.isnot = function(selector){
    return !this.is(selector);
  };

  // Override Jquery Validate checkForm function to allow validation of array inputs with same name
  // This is neccessary for the file and schema inputs
  $.validator.prototype.checkForm = function() {
    this.prepareForm()
    for (var i = 0, elements = (this.currentElements = this.elements()); elements[i]; i++) {
      // If there is more than one field with this name i.e. array fields
      if (this.findByName(elements[i].name).length !== undefined && this.findByName(elements[i].name).length > 1) {
        // Loop through elements with the same name and validate seperately
        for (var cnt = 0; cnt < this.findByName(elements[i].name).length; cnt++) {
          // Check it's not supposed to be ignored
          if ($(this.findByName(elements[i].name)[cnt]).isnot(this.settings.ignore)) {
            this.check(this.findByName(elements[i].name)[cnt])
          }
        }
      } else {
        this.check(elements[i]) // Validate uniquely named fields as normal
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
