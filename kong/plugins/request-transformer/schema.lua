return {
  fields = {
    remove = { 
      type = "table",
      schema = {
        fields = {
          form = { type = "array" },
          headers = { type = "array" },
          querystring = { type = "array" }
        }
      }
    },
    replace = { 
      type = "table",
      schema = {
        fields = {
          form = { type = "array" },
          headers = { type = "array" },
          querystring = { type = "array" }
        }
      }
    },
    add = { 
      type = "table",
      schema = {
        fields = {
          form = { type = "array" },
          headers = { type = "array" },
          querystring = { type = "array" }
        }
      }
    },
    append = { 
      type = "table",
      schema = {
        fields = {
          headers = { type = "array" },
          querystring = { type = "array" }
        }
      }
    }
  }
}
