extension HelloWorld

resource greeting 'Greeting' = {
  name: 'World'
}

resource notify 'HttpCall' = {
  name: 'testCall'
  url: 'https://lamian.robertprast.com'
  method: 'POST'
  body: '{"message": "hello from bicep!", "source": "HelloWorld extension"}'
  headers: [
    { name: 'Content-Type', value: 'application/json' }
  ]
}
