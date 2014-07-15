# Setup #


This example requires the Autobahn Websocket Test Suite in order to run. Here are the steps for setup:

(The main instructions can be found here: http://autobahn.ws/testsuite/installation.html)


1. Install the Autobahn Test Suite

```
git clone git://github.com/tavendo/AutobahnTestSuite.git
cd AutobahnTestSuite
git checkout v0.6.1
cd autobahntestsuite
python setup.py install
```


2. Start Autobahn server

> cd <your install path>/AutobahnTestSuite/autobahntestsuite
> python -m autobahntestsuite.wstest -m fuzzingserver


3. Update the app config file in the example

edit `app_config.lua` and modify `Config.deployment` with your IP address and port number of your setup. (Note: 9001 is the default port for the Autobahn test server)

```
Config.deployment = {
  -- 192.168.0.102, 192.168.3.120
  server_url = '192.168.0.102', -- or IP
  server_port = '9001',
  io_buffering_active = false
}
```

4. Run the example

Start the Corona SDK and load the example directory


# Results #

To see the results of the test:

1. Navigate to http://<your ip address>:8080/test_browser.html

click on button "Update Reports (manual)"

2. Navigate to http://<your ip address>:8080/cwd/reports/clients/index.html

All of the tests are shown with output on the right hand side