var currentLicenseStep = $("[data-step=1A]")
var licenseWizard = $('#license-wizard')
var buttons = $('.license-wizard-step button')

$('#show-license-wizard').click(function(event){
  event.preventDefault()
  if (licenseWizard.hasClass('hidden')) {
    licenseWizard.removeClass('hidden')
  } else {
    close()
  }
})

buttons.each(function(){
  $(this).click(function(){
    var action = $(this).data('action')
    var nextStep = $(this).data('next-step')

    if (action == 'restart') {
      restart()
    } else if (action == 'close') {
      close()
    } else if (nextStep) {
      loadStep(nextStep)
    }
  })
})

function close() {
  licenseWizard.addClass('hidden')
  loadStep('1A')
}

function restart() {
  loadStep('1A')
}

function loadStep(id) {
  var nextStep = $("[data-step=" + id + "]")
  currentLicenseStep.addClass('hidden')
  nextStep.removeClass('hidden')
  currentLicenseStep = nextStep
}