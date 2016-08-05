$(function() {
  var i = setInterval(function ()
    {
      if ($('#api_selector').length)
      {
          clearInterval(i);
          $('#api_selector').appendTo('.info_description')
      }
    }, 100);
})
