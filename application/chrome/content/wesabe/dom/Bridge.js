wesabe.provide('dom.Bridge');
wesabe.require('dom.page');

/**
 * Provides communication between XUL and HTML documents. Create a
 * +Bridge+ by initializing one with an +HTMLDocument+ and then calling
 * the +connect+ method:
 *
 *   var bridge = new wesabe.dom.Bridge(browser.contentDocument);
 *   bridge.connect();
 *
 * To evaluate some code over the bridge, use the +evaluate+ function:
 *
 *   bridge.evaluate("3+4", function(result){ alert("result="+result) });
 *
 * You can also pass a function instead of a string, but be aware that
 * the function's scope won't be included when it's run:
 *
 *   bridge.evaluate(
 *     // run on the HTML side
 *     function() {
 *       jQuery("*").click(function(event) {
 *         callback(jQuery(event.target).attr("id"));
 *       });
 *     },
 *     // run on the XUL side
 *     function(data) {
 *       var id = data[0];
 *       wesabe.info("id of clicked element was ", id);
 *     });
 */
wesabe.dom.Bridge = function(doc, callback) {
  var messageid = 1;

  this.connect = function(fn) {
    var script = wesabe.dom.Bridge.bootstrap.toSource();
    script = "("+script+")()";
    wesabe.dom.page.inject(doc, script);

    var self = this;
    setTimeout(function() {
      self.attach(fn);
    }, 10);
  };

  this.attach = function(fn) {
    var element = this.getBridgeElement();
    var self = this;

    element.addEventListener("xulRespond", function(event) {
      var response = eval(element.firstChild.nodeValue);
      self.dispatch(response);
    }, true);

    fn && fn.call(this);
  };

  this.getBridgeElement = function() {
    return doc.getElementById("_xulBridge");
  };

  this.evaluate = function(script, fn) {
    if (wesabe.isFunction(script)) {
      script = '('+script.toSource()+')()';
    }
    this.request('evaluate', script, fn);
  };

  this.request = function(methodName, data, fn) {
    var element = this.getBridgeElement();
    var request = {id: messageid++, data: data, method: methodName};
    wesabe.util.data(this, "callback."+request.id, fn);

    var event = document.createEvent("Events");
    event.initEvent("xulDispatch", true, false);

    element.setAttribute("request", request.toSource());
    element.dispatchEvent(event);
  };

  this.dispatch = function(response) {
    if (response.id) {
      var fn = wesabe.util.data(this, "callback."+response.id);
      if (fn) fn.call(response, response.data);
    } else {
      wesabe.warn('response did not contain an id');
    }
    wesabe.trigger(this, 'response', [response]);
  };

  callback && this.connect(callback);
};

/**
 * This function only exists so that the string inside it can be
 * +eval+'ed inside an HTML document that we want to communicate with.
 *
 * Therefore we don't have access to any of the cool stuff available
 * to the rest of the appliation, including logging, utility functions, etc.
 */
wesabe.dom.Bridge.bootstrap = function() {
  function _xulBridge() {
    /**
     * Returns the element that we use to communicate with the XUL side.
     *
     * @private
     */
    this.getBridgeElement = function() {
      var element = document.getElementById("_xulBridge");
      if (!element) {
        element = document.createElement("div");
        element.setAttribute("id", "_xulBridge");
        element.setAttribute("style", "display:none");

        var self = this;
        element.addEventListener("xulDispatch", function(event) {
          var element  = event.target;
          var request  = eval(element.getAttribute("request"));
          self.dispatch(request);
        }, true);

        document.documentElement.appendChild(element);
      }
      return element;
    };

    /**
     * Dispatches a request sent by the XUL side and returns a response.
     *
     * @param request
     *   * +id:+ the id of the message sent from the XUL side.
     *   * +method:+ the method to call on the HTML side of the bridge.
     *   * +data:+ the data sent by the XUL side.
     *
     * @private
     */
    this.dispatch = function(request) {
      var response;

      try {
        response = this[request.method].call(this, request);
      } catch(e) {
        response = e;
        response.source = request.data;
      }
      this.notifyXul(request.id, response);
    };

    /**
     * Evaluates some JavaScript and provides a +callback+ function useful for
     * sending multiple responses back to the XUL side.
     *
     * @param request
     *   * +id:+ the id of the message sent from the XUL side.
     *   * +method:+ the method to call on the HTML side of the bridge.
     *   * +data:+ the data sent by the XUL side.
     *
     * @private
     */
    this.evaluate = function(request) {
      var fn = new Function('__scope__',
        'return eval("with(__scope__){'+request.data.replace(/"/g, '\\"')+'}")');
      var self = this, scope = {callback: function() {
        var data = [];
        for (var i = 0; i < arguments.length; i++) {
          data.push(arguments[i]);
        }
        self.notifyXul(request.id, data)
      }};
      return fn.call(this, scope);
    };

    /**
     * Notifies the XUL side by id with the given data.
     *
     * @param id [Number]
     *   The number sent by the XUL side used for calling the right callback.
     * @param data
     *   The data to send back to the XUL side.
     *
     * @private
     */
    this.notifyXul = function(id, data) {
      var element = this.getBridgeElement();

      var event = document.createEvent("Events");
      event.initEvent("xulRespond", true, false);

      element.innerHTML = ""; // clear all children
      element.appendChild(document.createTextNode({id: id, data: data}.toSource()));
      element.dispatchEvent(event);
    };

    this.getBridgeElement();
  };

  window._xulBridge = new _xulBridge();
};
