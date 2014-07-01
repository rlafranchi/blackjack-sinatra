$(document).ready(function(){
  player_hit();
  player_stay();
  dealer_hit();
});

function player_hit() {
  $(document).on("click", "#hit", function() {
    $.ajax({
      type: 'POST',
      url: '/game',
      data: { hit: true, layout: false}
    }).done(function(msg){
      $("div#game").replaceWith(msg);
    });
    return false;
  });
}

function player_stay() {
  $(document).on("click", "#stay", function() {
    $.ajax({
      type: 'POST',
      url: '/game',
      data: { stay: true, layout: false}
    }).done(function(msg){
      $("div#game").replaceWith(msg);
    });
    return false;
  });
}
