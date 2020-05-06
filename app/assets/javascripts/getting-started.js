function addAccordionListeners() {
    var opener = document.getElementsByClassName("opener");
    var i;

    for (i = 0; i < opener.length; i++) {
        opener[i].addEventListener("click", function () {
					console.log(this.classList)
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

function anchorTagOpener() {
	$(document).ready(function() {
		let hash = window.location.hash.replace('#','');
		let opener = document.getElementsByClassName(hash)[0];
		var panel = opener.nextElementSibling;
		console.log(panel)

		opener.classList.toggle('active')

		if (panel.style.maxHeight) {
				panel.style.maxHeight = null;
		} else {
				panel.style.maxHeight = panel.scrollHeight + "px";
		}
		$(window).scrollTop($("." + hash).offset().top)
	})
}
