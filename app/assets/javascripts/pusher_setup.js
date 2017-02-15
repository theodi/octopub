"use strict";

function setUpPusher() {
  Pusher.host = 'ws-eu.pusher.com';
  Pusher.sockjs_host = 'sockjs-eu.pusher.com';
  var pusherKey = $('body').data('pusher-key');
  var pusherCluster = $('body').data('pusher-cluster');

  // Pusher cluster may be set differently in dev mode (for example)
  // So if set, use it, else default to whatever has been set up by
  // environment variables, namely PUSHER_URL
  if (pusherCluster.length) {
    var pusher =   new Pusher(pusherKey, {
      cluster: pusherCluster
    });
  } else {
    var pusher = new Pusher(pusherKey);
  }
  return pusher;
}
