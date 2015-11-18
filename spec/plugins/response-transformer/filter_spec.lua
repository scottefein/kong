local spec_helper = require "spec.spec_helpers"
local http_client = require "kong.tools.http_client"
local cjson = require "cjson"

local STUB_GET_URL = spec_helper.PROXY_URL.."/get"
local STUB_POST_URL = spec_helper.PROXY_URL.."/post"
local STUB_HEADERS_URL = spec_helper.PROXY_URL.."/response-headers"

describe("Response Transformer Plugin #proxy", function()

  setup(function()
    spec_helper.prepare_db()
    spec_helper.insert_fixtures {
      api = {
        {name = "tests-response-transformer", request_host = "response.com", upstream_url = "http://httpbin.org"},
        {name = "tests-response-transformer2", request_host = "response2.com", upstream_url = "http://httpbin.org"},
        {name = "tests-response-transformer3", request_host = "response3.com", upstream_url = "http://httpbin.org"},
        {name = "tests-response-transformer4", request_host = "response4.com", upstream_url = "http://httpbin.org"}
      },
      plugin = {
        {
          name = "response-transformer",
          config = {
            add = {
              headers = {"x-added:true", "x-added2:true", "x-added2:false"},
              json = {"newjsonparam:newvalue"}
            },
            remove = {
              headers = {"x-to-remove"},
              json = {"origin"}
            }
          },
          __api = 1
        },
        {
          name = "response-transformer",
          config = {
            add = {
              headers = {"Cache-Control:max-age=86400"}
            }
          },
          __api = 2
        },
        {
          name = "response-transformer",
          config = {
            add = {
              headers = {"h1:a1"}
            },
            append = {
              headers = {"h1:a2", "h1:a3", "h2:b1"}
            },
            replace = {
              headers = {"h1:a3", "h2:b1"}
            }
          },
          __api = 3
        },
        {
          name = "response-transformer",
          config = {
            add = {
              headers = {"h6:true"}
            },
            append = {
              headers = {"h1:a2", "h1:a3", "h2:b1"}
            },
            remove = {
              headers = {"h0"}
            },
            replace = {
              headers = {"h4:false", "h5:true",}
            }
          },
          __api = 4
        }
      }
    }

    spec_helper.start_kong()
  end)

  teardown(function()
    spec_helper.stop_kong()
  end)

  describe("Test adding parameters", function()

    it("should add new headers", function()
      local _, status, headers = http_client.get(STUB_GET_URL, {}, {host = "response.com"})
      assert.equal(200, status)
      assert.equal("true", headers["x-added"])
      assert.equal("true", headers["x-added2"])
    end)

    it("should add new parameters on GET", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "response.com"})
      assert.equal(200, status)
      local body = cjson.decode(response)
      assert.equal("newvalue", body["newjsonparam"])
    end)

    it("should add new parameters on POST", function()
      local response, status = http_client.post(STUB_POST_URL, {}, {host = "response.com"})
      assert.equal(200, status)
      local body = cjson.decode(response)
      assert.equal("newvalue", body["newjsonparam"])
    end)

    it("should add new headers", function()
      local _, status, headers = http_client.get(STUB_GET_URL, {}, {host = "response2.com"})
      assert.equal(200, status)
      assert.equal("max-age=86400", headers["cache-control"])
    end)

  end)

  describe("Test removing parameters", function()

    it("should remove a header", function()
      local _, status, headers = http_client.get(STUB_HEADERS_URL, {["x-to-remove"] = "true"}, {host = "response.com"})
      assert.equal(200, status)
      assert.falsy(headers["x-to-remove"])
    end)

    it("should remove a parameter on GET", function()
      local response, status = http_client.get(STUB_GET_URL, {}, {host = "response.com"})
      assert.equal(200, status)
      local body = cjson.decode(response)
      assert.falsy(body.origin)
    end)

  end)
  
  describe("Test appending parameters", function()
  
    it("should create new header if not its missing", function()
      local _, status, headers = http_client.get(STUB_GET_URL, {}, {host = "response3.com"})
      assert.equal(200, status)
      assert.equal("b1", headers["h2"])
    end)
  end)
  
  describe("Test remove, replace, add, append of headers", function()
    
    it("should remove a header", function()
      local _, status, headers = http_client.get(STUB_HEADERS_URL, {["h0"] = "true"}, {host = "response4.com"})
      assert.equal(200, status)
      assert.falsy(headers["h0"])
    end)
    
    it("should replace the value of a header", function()
      local _, status, headers = http_client.get(STUB_HEADERS_URL, {["h0"] = "true", ["h4"] = "true", ["h5"] = "false"}, {host = "response4.com"})
      assert.equal(200, status)
      assert.equal("false", headers["h4"])
      assert.equal("true", headers["h5"])
    end)
    
    it("should append value if header exists", function()
      local _, status, headers = http_client.get(STUB_GET_URL, {}, {host = "response3.com"})
      assert.equal(200, status)
      assert.equal("a1, a2, a3", headers["h1"])
    end)
    
    it("should add if header does not exist", function()
      local _, status, headers = http_client.get(STUB_HEADERS_URL, {}, {host = "response4.com"})
      assert.equal(200, status)
      assert.equal("true", headers["h6"])
    end)
    
    it("should not add if header exist", function()
      local _, status, headers = http_client.get(STUB_HEADERS_URL, {["h6"] = "false"}, {host = "response4.com"})
      assert.equal(200, status)
      assert.equal("false", headers["h6"])
    end)
    
    it("should create new header if not its missing", function()
      local _, status, headers = http_client.get(STUB_GET_URL, {}, {host = "response3.com"})
      assert.equal(200, status)
      assert.equal("b1", headers["h2"])
    end)
    
    it("should append value if header exists", function()
      local _, status, headers = http_client.get(STUB_GET_URL, {}, {host = "response3.com"})
      assert.equal(200, status)
      assert.equal("a1, a2, a3", headers["h1"])
    end)
  end)
end)
