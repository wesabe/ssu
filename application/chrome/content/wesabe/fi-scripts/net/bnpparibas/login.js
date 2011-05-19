// This part handles logging in, and contains all the
// logic and page element references related to it.
wesabe.require('canvas.geometry.*');

wesabe.provide("fi-scripts.net.bnpparibas.login", {
  dispatch: function() {
    if (page.present(e.logoff.link)) return;

    if (page.present(e.login.error.user)) {
      job.fail(401, 'auth.user.invalid');
    } else if (page.present(e.login.error.pass)) {
      job.fail(401, 'auth.pass.invalid');
    } else if (page.present(e.login.error.creds)) {
      job.fail(401, 'auth.creds.invalid');
    } else if (page.present(e.login.error.general)) {
      job.fail(401, 'auth.unknown');
    } else if (page.present(e.login.error.noAccess)) {
      job.fail(403, 'auth.noaccess');
    } else if (page.present(e.login.user.field)) {
      action.login();
    }
  },

  actions: {
    // sample -- replace this with your own custom logic
    login: function() {
      // reset any password that might be there
      page.click(e.login.pass.reset);

      page.fill(e.login.user.field, answers.username);

      var image = wesabe.untaint(page.findStrict(e.login.pass.image));
      // wait for the image to load
      wesabe.bind(image, 'load', function() {
        // create a canvas to draw in
        var canvas = page.createElement("canvas");
        canvas.setAttribute("id", "wesabe-grille-canvas");
        canvas.setAttribute("width", image.width);
        canvas.setAttribute("height", image.height);
        page.body.appendChild(canvas);

        // get the drawing context and draw the grille onto it
        var context = canvas.getContext("2d");
        wesabe.debug("Using image: ", image);
        context.drawImage(image, 0, 0);

        // FIXME: 2009-01-05 <brian@wesabe.com> For some reason this JavaScript context
        // cannot read the image data from the page using getImageData(), so we use the
        // bridge to read it indirectly.
        new wesabe.dom.Bridge(page.proxyTarget, function() {
          this.evaluate(
            // evaluated on the page
            function() {
              var canvas = document.getElementById("wesabe-grille-canvas");
              var context = canvas.getContext("2d");
              var data = context.getImageData(0, 0, canvas.width, canvas.height).data;
              callback('grille-data', {data: data, size: {width: canvas.width, height: canvas.height}});
            },

            // evaluated here on callback
            function(message) {
              var type = message[0], payload = message[1];
              if (type == "grille-data") {
                tmp.passImageData = new wesabe.canvas.geometry.ImageData(
                  wesabe.canvas.geometry.Rect.make(0, 0, payload.size.width, payload.size.height),
                  payload.data
                );
                action.processPassImage();
              }
            }
          );
        });
      });
    },

    pass: function() {
      // fill out the field by clicking the right buttons
      for (var i = 0; i < answers.password.length; i++) {
        page.click(tmp.digitAreaMap[answers.password[i]].element);
      }

      // submit the form
      page.click(e.login.continueButton);
    },

    // This is a bit crazy and requires some explanation.
    // Basically, BNP Paribas has a single image and an image map
    // that is a 5x5 grid. The digits 0-9 are distributed randomly,
    // occupying 10 out of 25 of the spots. The user then must click
    // on the digits of his or her password in order, populating a
    // password field that contains a mapped version of the password.
    //
    // Let's say we have a password grid like this:
    //
    //                -  -  1  -  2
    //                3  -  4  -  -
    //                -  5  6  -  7
    //                -  -  -  -  -
    //                -  8  -  9  0
    //
    // Each square on the grid has a value of 01 to 25, like so:
    //
    //                01 02 03 04 05
    //                06 07 08 09 10
    //                11 12 13 14 15
    //                16 17 18 19 20
    //                21 22 23 24 25
    //
    // So if I click on the "3", the mapped value is "06". If my
    // password is "254164", then the mapped value is "051208031308".
    // If I give the server the right mapped password, then I must be
    // (a) the owner of the account and (b) not a bot.
    //
    // The problem is that this mapping is stored on the server and
    // is only accessible on the client if you can interpret the image
    // correctly.
    //
    // This function takes advantage of the fact that the clickable
    // parts of the image (the digits and the blank space) do not change
    // (with few exceptions) when they move from square to square.
    // Therefore we can look at that portion of the image and generate
    // an md5 signature of that portion of the image and look up the
    // digit it maps to using our stored mapping of signatures to digits.
    //
    // This method is VERY brittle, and will break if they change the
    // slightest thing about the numeric parts of the image.
    processPassImage: function() {
      var imageSignatureMap = {
        '51a9107d2e5b39fd584d38ebc9943948': NaN, // blank spot
        '5c6f9649d91b0e5b2aa253a2ea3a9316': 1,
        '2b7fc838971f607fb6dd9bd3464fbcdd': 2,
        'a97dc836e72fd06305bd8c6b40e7be7b': 3,
        '0fb187b530184cbbd20de2959bc9289b': 4,
        'a30ba739c24fc0941b95f6d5da5fd7d8': 5,
        'd96b294ca46d3949ad91cd703514eb09': 6,
        '0bea694d6f46dc6d995dec6955a31b00': 7,
        'e8e92f4fbda19ee6211a9b8a2d9e1410': 8,
        'a497b31c2b345705e4810fd931f00807': 9,
        '7368ce318266ed36299602c9720a6596': 0,
      };

      var image = tmp.passImageData, center = image.rect.center.nearestPixel;

      var areas = page.select(e.login.pass.areas).map(function(area) {
        var coords = area.getAttribute("coords").split(",").map(function(n){ return parseInt(n) });
        return {
          element: area,
          rect: wesabe.canvas.geometry.Rect.fromPoints(
            new wesabe.canvas.geometry.Point(coords[0], coords[1]),
            new wesabe.canvas.geometry.Point(coords[2], coords[3])
          ),
        };
      });

      var grid = [];
      tmp.digitAreaMap = {};

      wesabe.debug("Area coordinates and their signatures:");
      for (var i = 0; i < areas.length; i++) {
        var area = areas[i],
            signature = image.withRect(area.rect).signature,
            digit = imageSignatureMap[signature];

        wesabe.debug(signature, ' -- ', area.rect);
        grid.push(wesabe.isUndefined(digit) ? '?' : isNaN(digit) ? '-' : digit);

        // populate the password digit -> area map
        tmp.digitAreaMap[digit] = area;
      }

      wesabe.debug("Here's what I think the password map grid looks like:");
      for (var i = 0; i < 5; i++) {
        wesabe.debug(grid.slice(i * 5, (i+1) * 5).join(' '));
      }

      action.pass();

      /*


      Here are some more experiments with the image detection stuff
      that may come in handy later. The first is figuring out the
      bounds of the grid inside the image. The second is finding all
      the corners of the grid squares.

      I didn't use these because the HTML gives us an imagemap that
      has all the coordinates we need, but this stuff might be useful
      in spotting changes and altering us to a problem.


      var borderColor = [0, 102, 52, 255];

      // figure out what the rect of the actual grid within the image is
      var gridRect = wesabe.canvas.geometry.Rect.fromPoints(
        new wesabe.canvas.geometry.Point(
          image.findPoint({
            start: new wesabe.canvas.geometry.Point(0, center.y),                 // start at left middle
             step: new wesabe.canvas.geometry.Size(1, 0),                         // stepping right
            color: borderColor
          }).x,

          image.findPoint({
            start: new wesabe.canvas.geometry.Point(center.x, 0),                 // start at top middle
             step: new wesabe.canvas.geometry.Size(0, 1),                         // stepping down
            color: borderColor,
          }).y
        ),

        new wesabe.canvas.geometry.Point(
          image.findPoint({
            start: new wesabe.canvas.geometry.Point(image.rect.right, center.y),  // start at right middle
             step: new wesabe.canvas.geometry.Size(-1, 0),                        // stepping left
            color: borderColor,
          }).x,

          image.findPoint({
            start: new wesabe.canvas.geometry.Point(center.x, image.rect.bottom), // start at bottom middle
             step: new wesabe.canvas.geometry.Size(0, -1),                        // stepping up
            color: borderColor,
          }).y
        )
      );

      wesabe.debug("image.rect = ", image.rect, ", gridRect = ", gridRect);

      var corners = image.findPoints({
        bound: gridRect,
         test: function(p) {
           // make sure the point itself is a border and at least one of
           // top-left, top-right, bottom-left, and bottom-right is too
           return image.pointHasColor(p, borderColor) &&
                    (image.pointHasColor(p.withOffset(1, 0), borderColor) || image.pointHasColor(p.withOffset(-1, 0), borderColor)) &&
                    (image.pointHasColor(p.withOffset(0, -1), borderColor) || image.pointHasColor(p.withOffset(0, 1),  borderColor));
         },
      });

      // add the corners of the grid, since they're rounded and won't be found by the above
      corners.push(gridRect.origin);                                  // top-left
      corners.push(gridRect.origin.withOffset(gridRect.width, 0));    // top-right
      corners.push(gridRect.origin.withOffset(0, gridRect.height));   // bottom-left
      corners.push(gridRect.origin.withOffset(gridRect.size));        // bottom-right

      wesabe.debug("corners = ", corners);

      */
    },

    // sample -- replace this with your own custom logic
    logoff: function() {
      page.click(e.logoff.link);
      // tells PFC that the job succeeded, and stops XulRunner (after a timeout)
      job.succeed();
    },
  },

  // elements are xpaths or sets of xpaths that
  // illustrate how to access a particular element
  // on a page
  //
  // used by the page.* methods, available as "e"
  // in dispatch and actions
  elements: {
    login: {
      user: {
        field: [
          '//form[@name="logincanalnet"]//input[@type="text"][@name="ch1"]',
        ],
      },

      pass: {
        field: [
          '//form[@name="logincanalnetbis"]//input[@type="password"][@name="ch2"]',
          '//input[@type="password"][@name="ch2"]',
          '//form[@name="logincanalnetbis"]//input[@type="password"]',
        ],

        image: [
          '//img[@usemap="#MapGril"]',
          '//img[@src="/NSImgGrille"]',
        ],

        areas: [
          '//map[@name="MapGril"]//area',
          '//map[count(area)=25]//area',
        ],

        reset: [
          '//a[contains(string(.), "Corriger")]',
          '//a[contains(@href, "ReInit")]',
        ],
      },

      continueButton: [
        '//a[@href="javascript:valider2();"]',
      ],

      // possible error messages that you'll encounter logging in
      // it's likely that the bank will either show "invalid user"
      // and "invalid password" OR "invalid username and/or password",
      // but not both, so you'll probably need to trim some of this
      error: {
        user: [
          // for example
          '//text()[contains(., "Invalid username")]',
        ],

        pass: [
          // for example
          '//text()[contains(., "Invalid password")]',
        ],

        creds: [
          // for example
          '//text()[contains(., "Invalid username or password")]',
        ],

        general: [
          // for example
          '//text()[contains(., "Could not log you in")]',
        ],

        noAccess: [
          // for example
          '//text()[contains(., "Your account has been locked")]',
        ],
      },
    },

    logoff: {
      link: [
        // for example
        '//a[contains(string(.), "Logoff") or contains(string(.), "Logout")][contains(@href, "Logff")]',
      ],
    },
  },
});

// mask things like Grille('12') and 6,5,25,24 (the coords string) which would give away the password digits
wesabe.util.privacy.registerSanitizer('Area Map Info', /Grille\('\d+'\)|\d+,\d+,\d+,\d+/g);
