function get_targets() {
  return prompt('List comma-separated targets or just hit enter', 'target').split(',');
}

function attack_reset(button) {
  $(button).next('span.result').html("");
}

function attack_roll(button) {
  var targets = get_targets();
  var results = [];
  var i;
  for (i=0; i<targets.length; i++) {
    var new_results
    new_result = "vs " + targets[i] + "(" + $(button).attr('vsDefense') + "): "
    new_result += resultStr(roll( '1d20+' + $(button).attr("attackBonus") ));
    results.push(new_result);
  }
  if ($(button).attr("damageRoll") != "") {
    results.push( "for " + resultStr(roll($(button).attr("damageRoll"))) + " " + $(button).attr("damageType") + " damage" );    
  }

  $(button).parent().children("span.result").html(
    "<ul><li>" + results.join("</li><li>") + "</li></ul>"
  );
}

$(document).ready(function(){
  
});