extension HelloWorld

resource greeting 'Greeting' = {
  name: 'World'
}

output message string = greeting.Message
