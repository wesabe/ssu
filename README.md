XulRunner Uploader
==================

This uploader uses pre-recorded scripts to automate statement uploads. For build and installation
instructions, see INSTALL. There are two scripts provided to help run test it:

    $ script/server

This script starts the application on Linux or Mac OS X (which needs a `rake build:dev` first)
and tails the log.

    $ script/console

This script starts an IRB session with some `method_missing` magic that lets you call into the
running XulRunner. For example, getting the status of a running job:

>> job.status
=> {"completed"=>nil, "result"=>nil, "status"=>nil, "fid"=>"us-001069", "jobid"=>nil, "elapsed"=>1929}

Or to start a job:

>> job.start "fid"=>"us-001069", "creds"=>{"userId"=>"wamu-user", "password"=>"wamu-pass"}, "wesabe"=>{"username"=>"wesabe-user", "password"=>"wesabe-pass"}
=> nil


Credentials
-----------

Rather than passing all that junk every time, you can store your credentials in individual files
in the `credentials` directory at this level. For example:

    $ cat credentials/wamu
    {"creds":
      {"userId": "wamu-user",
       "password": "wamu-pass"},
     "fid": "us-001069",
     "wesabe": {
       "username": "wesabe-user",
       "password": "wesabe-pass"
     }}

And then starting a job for WaMu becomes:

    >> job.start wamu
    => nil

To add your own credentials, just use the included generator:

    $ script/generate credential us-001069 wamu

Which will create a JSON file at `credentials/wamu` for you to fill out.


Adding Your Own Player
----------------------

To start adding support for a financial institution you can use the player generator:

    $ script/generate player us-001069
      [ADDED] fi-scripts/us-001069.js
      [ADDED] fi-scripts/us-001069/login.js
      [ADDED] fi-scripts/us-001069/accounts.js

It will ask for your Wesabe username and password to get some information about the FI
you identified with the Wesabe ID, using that to fill in the player script.

As long as you've created a credential file for your new player, trying it out should be
just a matter of:

    # terminal 1
    $ script/server

    # terminal 2
    $ script/console
    >> job.start wamu

It will only go to the login page, and may log errors in the server window (terminal 1),
but it should provide a basis for you to build from.
