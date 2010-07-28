function sleep(seconds) {
  var start = new Date().getTime();
  var end   = start + seconds * 1000;
  while (end > new Date().getTime());
}

Screw.Matchers['be_greater_than'] = {
  match: function(expected, actual) {
    return expected < actual;
  }, 
  
  failure_message: function(expected, actual, not) {
    return 'expected ' + $.print(actual) + (not ? ' not' : '') + ' to be greater than ' + $.print(expected);
  }
};

$(Screw).bind('loaded', function() {
  $('.it').fn({
    name: function() {
      return $(this).find('h2').html();
    }, 
    
    fullName: function() {
      return $(this).fn('parent').fn('fullName') + ' ' + $(this).fn('name');
    }
  });

  $('.describe').fn({
    root: function() {
      return $(this).is('div');
    }, 
    
    name: function() {
      return $(this).fn('root') ? "" : $(this).find('h1').html();
    }, 
    
    fullName: function() {
      if ($(this).fn('root')) return "";
      var prefix = $(this).fn('parent').fn('fullName');
      var middle = ' ';
      var suffix = $(this).fn('name');
      
      if (/^#/.test(suffix)) middle = '';
      return prefix + middle + suffix;
    }
  });
  
  // $('.it').bind('passed', function(event) {
  //   console.log('passed', $(event.target).fn('fullName'));
  // });
  // $('.it').bind('failed', function(event) {
  //   console.log('failed', $(event.target).fn('name'));
  // });
});
