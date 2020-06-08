function addAccordionListeners() {
  var opener = document.getElementsByClassName("opener");
  var i;

  for (i = 0; i < opener.length; i++) {
    opener[i].addEventListener("click", function () {
      this.classList.toggle("active");
      var panel = this.nextElementSibling;
      if (panel.style.maxHeight) {
        panel.style.maxHeight = null;
      } else {
        panel.style.maxHeight = panel.scrollHeight + "px";
      }
    });
  }
}

function readMoreAboutLicensesOpener() {
  var link   = $('#read-more-about-licenses')
  var button = $('#making-data-open-button')
  var panel  = button.next()

  link.click(function(e) {
    e.preventDefault()

    button.addClass("active");

    $('html, body').animate({
      scrollTop: button.offset().top
    }, 250);

    panel.css('maxHeight', panel.get(0).scrollHeight + 'px')
  })
}
