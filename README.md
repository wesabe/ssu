SSU
===

SSU is a scripted web site navigator & scraper. It was originally designed
and conceived as part of Wesabe's infrastructure and has since been
open-sourced. Its original design goal was to extract [OFX][ofx] data
given bank usernames and passwords for use on wesabe.com.

[ofx]: http://en.wikipedia.org/wiki/Open_Financial_Exchange

The system it uses to get this data is [XulRunner][XulRunner], a project from Mozilla
that provides a customizable (and scriptable) browser. SSU has scripts
for each financial institution it supports that describes how to log in
and download data from that institution's web site.

[XulRunner]: https://developer.mozilla.org/en/XULrunner

It was originally written in JavaScript but is currently mostly
[CoffeeScript][CoffeeScript]. You can write bank scripts in either language, though
CoffeeScript will be the preferred one going forward.

[CoffeeScript]: http://jashkenas.github.com/coffee-script/


Why would I use this?
---------------------

If you're trying to aggregate transaction data from multiple financial
institutions, possibly for a large number of people, then this project
might be useful to you.


How do I try this out?
----------------------

First, clone the SSU repo:

    $ git clone https://github.com/wesabe/ssu

The easiest way to try this is on your laptop/desktop computer running
Linux or Mac OS X. Windows isn't supported. SSU comes with a bunch of
scripts for financial institutions that it already supports. Your
initial experience trying out SSU is going to be much easier if you have
an account at one of these institutions. To check, go to the
[fi-scripts][fi-scripts] folder and start looking for your bank. Let's
say your bank is Chase, whose site is chase.com. We store the scripts
for financial institutions in a reverse DNS folder structure, so you
need to look in the `com` directory for the `chase.coffee` script.

[fi-scripts]: https://github.com/wesabe/ssu/tree/master/application/chrome/content/wesabe/fi-scripts

If your financial institution is supported, then great! Next you'll need
to install XulRunner. If you're on Linux, you'll want to use your
package manager (e.g. `apt-get`). If you're on OS X you can use the
bundled setup script:

    ssu$ ./bootstrap

That'll install it if it's not installed and tell you the version you
have installed if it is already. Now go ahead and start the app itself
in a terminal window:

    ssu$ bin/server

You'll see some logging output along with some startup messages and a
blank browser window titled "Wesabe DesktopUploader". As long as you
don't see any errors you should be good to go. Next you can generate
a credentials file to test with. Again, let's assume you have an
account at Chase. In another terminal window, run this:

    ssu$ bundle
    ssu$ bundle exec script/generate credential com.chase chase

That'll create a file at `credentials/chase` that looks like this:

    {"creds": {"username": "FIUSERNAME", "password": "FIPASSWORD"}, "fid": "com.chase"}

Just change `FIUSERNAME` and `FIPASSWORD` to your username and password
for Chase and save the file.

Now fire up the test client and start a job:

    ssu$ script/console
    >> job.start chase

Your first terminal window and the blank browser should now be doing
something -- ideally logging into your financial institution site and
getting your recent transaction data. If it succeeds it'll store the
downloaded statement's in the app's profile directory. You can get a
list like so from the console:

    >> statement.list
    => ["1D8787AA-6D2D-0001-DFF3-9EB052301CD4"]
    >> statement.read "1D8787AA-6D2D-0001-DFF3-9EB052301CD4"
    => "OFXHEADER:100\r\n..."

Congrats, you've successfully gotten data out of your financial
institution's website!


So how do I use this for real?
------------------------------

The original application that used SSU is the one SSU was written for at
Wesabe: [pfc][pfc]. You can see how to manage SSU in [this file that controls
the SSU process][daemon] and [this file that talks to it][sync_job].

[pfc]: https://github.com/wesabe/pfc
[daemon]: https://github.com/wesabe/pfc/blob/master/app/models/ssu/daemon.rb
[sync_job]: https://github.com/wesabe/pfc/blob/master/app/models/ssu/sync_job.rb

Basically, SSU sets up a tiny HTTP server (at port 5000 by default) for commands.
Here's a request to list all the statements that have been downloaded:

    POST /_legacy HTTP/1.0

    {"action": "statement.list"}

Here's one that starts a job with credentials:

    POST /_legacy HTTP/1.0
    Content-Type: application/json
    Content-Length: 76

    {"action": "job.start", "body": {"fid":"com.ingdirect", "creds":{"username":"joesmith","password":"iamgod"}}}

Responses will be in JSON regardless of what Accept header you pass:

    # a successful response to the /statements request
    HTTP/1.0 200 OK
    Content-Type: application/json

    {"status": "ok", "statements": ["1D8787AA-6D2D-0001-DFF3-9EB052301CD4"]}

    # an example error response
    {"status": "error", "error": "ReferenceError: foo is not defined"}

**NOTE:** The `/_legacy` route is a temporary compatibility measure with the
old pure-socket way of communicating with SSU. Eventually it'll be replaced by
REST-based routes (e.g. `GET /statements`, `POST /jobs`, etc).

You can use any programming language you like that supports spawning processes
and HTTP to manage an SSU instance. This project ships with development tools
that also serve as basic examples in the [server][server] (spawning) and
[console][console] (communication & managing via [api.rb][api.rb]) scripts.

[server]: https://github.com/wesabe/ssu/blob/master/bin/server
[console]: https://github.com/wesabe/ssu/blob/master/script/console
[api.rb]: https://github.com/wesabe/ssu/blob/master/script/api.rb

My bank isn't supported. Can I add it?
--------------------------------------

Yep, there's a generator for that which will build a skeleton script for your
financial insitution:

    ssu$ bundle
    ssu$ bundle exec script/generate player com.ally "Ally Bank" https://www.ally.com/
    Generating with player generator:
         [ADDED]  application/chrome/content/wesabe/fi-scripts/com/ally.coffee
         [ADDED]  application/chrome/content/wesabe/fi-scripts/com/ally/login.coffee
         [ADDED]  application/chrome/content/wesabe/fi-scripts/com/ally/accounts.coffee

You can probably leave the base script (`ally.coffee` in this example) alone
and start filling in `login.coffee` with the info required to navigate the
site. Once you've added something and created a matching credential file, go
ahead and try it out:

    ssu$ script/console
    >> job.start ally

There are lots of examples in the `fi-scripts` directory for you to reference
as you build your own script. Once you're satisfied just commit your files and
send a pull request so we can add your financial institution for others to use.


Why use a browser?
------------------

Using XulRunner means that SSU can access any bank site that Firefox can, so
you don't have to use mechanize or some other tool that doesn't fully emulate
the browser environment. This matters because, by its nature, navigating any
website in a scripted way is brittle and anything we can do to reduce the
breakage is good. Websites are intended to be viewed in web browsers and their
authors worked hard to make that function properly -- that is work you don't
have to do when you use a browser as your scraper.
