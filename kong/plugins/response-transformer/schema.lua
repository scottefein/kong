return {
  fields = {
    -- add: Add a value (to response headers or response JSON body) only if the key does not already exist.
    add = {
      type = "table",
      schema = {
        fields = {
          --json = {type = "array"},
          headers = {type = "array", default = {}}
        }
      }
    },
    remove = { 
      type = "table",
      schema = {
        fields = {
          --json = {type = "array"},
          headers = {type = "array", default = {}}
        }
      }
    },
    append = { 
      type = "table", 
      schema = {
        fields = {
          headers = {type = "array", default = {}}
        }
      }
    },
    replace = {
      type = "table", 
      schema = {
        fields = {
          headers = {type = "array", default = {}}
        }
      }
    }
  }
}
