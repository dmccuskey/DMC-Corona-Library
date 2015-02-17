### Example: dmc-websockets-autobahntestsuite ###

This example requires the Autobahn Websocket Test Suite. 


#### Setup AutoBahn Test Suit ####

(The main instructions can be found here: http://autobahn.ws/testsuite/installation.html)

1. Install the Autobahn Test Suite

  Two ways to install, via `pip` or sources. Using `pip` will install everything including dependencies.
  
  ```
  pip install autobahntestsuite
  ```
  
  ```
  git clone git://github.com/tavendo/AutobahnTestSuite.git
  cd AutobahnTestSuite
  git checkout v0.7.1
  cd autobahntestsuite
  python setup.py install
  ```

1. Start Autobahn server

  ```
  cd <your install path>/AutobahnTestSuite/autobahntestsuite
  python -m autobahntestsuite.wstest -m fuzzingserver
  ```


#### Setup Corona App ####

1. Update the app config file in the example

  edit `app_config.lua` and modify `Config.deployment` with your IP address and port number of your setup. (Note: 9001 is the default port for the Autobahn test server)

  ```
  Config.deployment = {
    -- 192.168.0.102, 192.168.3.120
    server_url = '192.168.0.102', -- or IP
    server_port = '9001',
    io_buffering_active = false
  }
  ```

1. Run the example

  Start the Corona SDK and load the example directory


### Results ###

To see the results of the test:

1. Navigate to http://`<your-test-server-ip-address>`:8080/test_browser.html

  click on button "Update Reports (manual)"

1. Navigate to http://`<your-test-server-ip-address>`:8080/cwd/reports/clients/index.html

  All of the tests are shown with output on the right hand side
