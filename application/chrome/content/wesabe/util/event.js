wesabe.provide('event');

// shamelessly adapted from jQuery
wesabe.util.event = {
  guid: 0, 
  
  add: function(elem, type, handler) {
    if (wesabe.isString(elem)) {
      handler = type;
      type = elem;
      elem = wesabe;
    }
    
    // ignore text and comment nodes
    if (elem.nodeType == 3 || elem.nodeType == 8)
      return;
    
    if (!handler.guid)
      handler.guid = ++wesabe.util.event.guid;
    
    var events = wesabe.util.data(elem, 'events') || wesabe.util.data(elem, 'events', {});
    var handlers = events[type];
    
    if (!handlers)
      handlers = events[type] = {};
    
    handlers[handler.guid] = handler;
    
    if (elem.addEventListener)
      elem.addEventListener(type, handler, false);
  }, 
  
  remove: function(elem, type, handler) {
    if (wesabe.isString(elem)) {
      handler = type;
      type = elem;
      elem = wesabe;
    }
    
    // ignore text and comment nodes
    if (elem.nodeType == 3 || elem.nodeType == 8)
      return;
    
    var events = wesabe.util.data(elem, 'events') || wesabe.util.data(elem, 'events', {});
    
    if (!type) {
      // remove all events for elem
      for (type in events)
        wesabe.util.event.remove(elem, type);
    } else {
      // remove events of a specific type
      if (events[type]) {
        if (handler) {
          // remove a specific handler
          delete events[type][handler.guid];
          if (elem.removeEventListener)
            elem.removeEventListener(elem, type, handler);
        } else {
          // remove all handlers for type
          for (handler in events[type])
            wesabe.util.event.remove(elem, type, events[type][handler]);
        }
      }
    }
  }, 
  
  trigger: function(elem, types, data) {
    if (wesabe.isString(elem)) {
      data = types;
      types = elem;
      elem = wesabe;
    }
    
    var events = wesabe.util.data(elem, 'events') || wesabe.util.data(elem, 'events', {});
    var forwards = wesabe.util.data(elem, 'event-forwards');
    
    types.split(/\s+/).forEach(function(type) {
      if (events[type]) {
        data = wesabe.lang.array.from(data || []);
        
        if (!data[0] || !data[0].preventDefault)
          data.unshift({type: type, target: elem});
        
        for (handler in events[type]) {
          events[type][handler].apply(elem, data);
        }
      }
    });
    
    if (forwards) {
      forwards.forEach(function(felem) {
        wesabe.util.event.trigger(felem, types, data);
      });
    }
  }, 
  
  forward: function(from, to) {
    var forwards = wesabe.util.data(from, 'event-forwards') || wesabe.util.data(from, 'event-forwards', []);
    forwards.push(to);
  }
};

wesabe.bind = wesabe.util.event.add;
wesabe.unbind = wesabe.util.event.remove;
wesabe.trigger = wesabe.util.event.trigger;
wesabe.one = function(elem, type, fn) {
  if (wesabe.isString(elem)) {
    fn = type;
    type = elem;
    elem = wesabe;
  }
  
  wesabe.bind(elem, type, function() {
    wesabe.unbind(this, type, arguments.callee);
    return fn.apply(this, arguments);
  });
};
