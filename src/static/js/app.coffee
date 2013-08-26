'use strict'

pushApp = angular.module 'pushApp', ['ngResource']

pushApp.config ['$routeProvider', '$locationProvider', ($routeProvider, $locationProvider) ->

  $routeProvider
    .when '/',
      templateUrl: 'clients.html'
      controller: 'clientsController'
    .when '/tokens/:client_id',
      templateUrl: 'tokens.html'
      controller: 'tokensController'
    .when '/tags/:client_id',
      templateUrl: 'tags.html'
      controller: 'tagsController'
    .when '/pushes/:client_id',
      templateUrl: 'pushes.html'
      controller: 'pushesController'
    .otherwise
      redirectTo: '/'

  $locationProvider.hashPrefix '!'

  console.log 'config'

  return
]

pushApp.factory 'Api', ['$resource', ($resource) ->
  console.log 'api'
  Api = $resource appConfig.apiUrl + ':first/:second/:third/:fourth', {},
    get: 
      method: "GET"
      isArray: true
    getOne: 
      method: "GET"
    post: 
      method: "POST"
    postArray: 
      method: "POST"
      isArray: true
    put: 
      method: "PUT"
  Api
]

pushApp.factory 'Utils', ->

  utils =

    tagsToArray: (string) ->
      if string
        tags = string.split ','
        tags = tags.map (el) ->
          el.replace /\s/g, ''
        tags

    tagsToString: (array) ->
      if array
        array.join ', '

    idsToArray: (string) ->
      if string
        string.split "\n"

    prepareQuery: (object) ->
      query = {}
      if object.ids?
        query.ids = this.idsToArray object.ids
        return query
      if object.and?
        query.and = this.tagsToArray object.and
      if object.or?
        query.or = this.tagsToArray object.or
      if object.not?
        query.not = this.tagsToArray object.not
      query
  utils

pushApp.filter 'truncate', ->
  (text) ->
    len = text.length
    if len > 20
      text = text.substr(0, 10) + '...' + text.substr(-10)
    text

pushApp.controller 'menuController', ['$scope', '$location', ($scope, $location) ->

  $scope.getClass = (path) ->
    if $location.path().substr(0, $location.path().indexOf('/', 1)) == path
      'active'
    else
      ''
]

pushApp.controller 'clientsController', ['$scope', 'Api', ($scope, Api) ->

  $scope.getClients = ->
    Clients = Api.bind first: 'client'
    _clients = Clients.get ->
      clients = {}
      for i of _clients
        clients[_clients[i].id] = _clients[i]
      $scope.clients = clients
      return
    return

  $scope.addClient = () ->
    Clients = Api.bind first: 'client'
    Clients.post "name":$scope.client.name, (data) ->
      console.log 'post', data
      $scope.clients[data.id] = data
      $scope.client = {}
      $scope.hideForm()
      return

  $scope.saveClient = (id) ->
    Clients = Api.bind first: 'client', second: id
    Clients.put "name":$scope.client.name, (data) ->
      console.log 'put', data
      if data.status == true
        $scope.clients[id].name = $scope.client.name
        $scope.client = {}
        $scope.hideForm()
      return
    return

  $scope.editClient = (id) ->
    console.log 'edit', id
    $scope.formClient = true
    Clients = Api.bind first: 'client', second: id
    client = Clients.getOne ->
      console.log 'client', client
      $scope.client = client
      return
    return

  $scope.removeClient = (id) ->
    Clients = Api.bind first: 'client', second: id
    Clients.delete (data) ->
      console.log 'delete', data
      if data.status == true
        delete $scope.clients[id];
      return
    return

  $scope.newClient = ->
    $scope.client = {}
    $scope.formClient = true
    return

  $scope.hideForm = ->
    $scope.formClient = false
    return

  $scope.addAuth = (id) ->
    console.log 'add auth', id
    $scope.authClient = $scope.clients[id]
    $scope.formAuthClient = true
 
  $scope.clearAuth = (id) ->
    console.log 'clear auth', id
    AuthKeys = Api.bind first: id, second: 'key', third: 'gcm'
    AuthKeys.delete (data) ->
      if data.status == true
        $scope.clients[id]["api_keys"]["gcm"].key = ''
    return

  $scope.hideAuthForm = ->
    $scope.formAuthClient = false
    return

  $scope.updateAuthKey = ->
    AuthKeys = Api.bind first: $scope.authClient.id, second: 'key', third: 'gcm'
    AuthKeys.put "key":$scope.authClient["api_keys"].gcm.key, (data) ->
      if data.status == true
        $scope.hideAuthForm()
      console.log 'update key', data
      return
    return

  $scope.getClients()

  return
]

pushApp.controller 'tokensController', ['$scope', '$rootScope', '$routeParams', 'Api', 'Utils', ($scope, $rootScope, $routeParams, Api, Utils) ->

  clientId = $rootScope["client_id"] = $routeParams["client_id"]

  dataToString = (data) ->
    parsed =
      ids:''
      tags:''
    for i of data
      parsed.ids = data[i].id
      if "tags" of data[i]
        parsed.tags = Utils.tagsToString data[i].tags
    parsed

  dataToArray = (data) ->
    console.log 'data to array', data
    parsed =
      ids:[]
      tags:[]
    parsed.ids = Utils.idsToArray data.ids
    parsed.tags = Utils.tagsToArray data.tags
    parsed

  $scope.query = {}

  Clients = Api.bind first: 'client', second: clientId
  client = Clients.getOne ->
    console.log 'client', client
    $scope.client = client
    return

  limit = appConfig.paging.limit
  Tokens = Api.bind first: clientId, second: 'ids'
  tokens = Tokens.get limit:1000, ->
    console.log 'tokens get', tokens
    $scope.tokens = tokens
    return

  $scope.newToken = ->
    $scope.token = {}
    $scope.tokenIndex = null
    $scope.formToken = true
    return

  $scope.hideTokenForm = ->
    $scope.formToken = false
    return

  $scope.searchTokens = ->
    $scope.formSearch = true
    return

  $scope.hideSearchTokenForm = ->
    $scope.formSearch = false
    return

  $scope.findTokens = ->
    console.log 'find tokens', $scope.query
    send = {}
    send.q = Utils.prepareQuery $scope.query.q
    Tokens = Api.bind first: clientId, second: 'ids', third: 'list'
    Tokens.postArray send.q, (data) ->
      console.log 'send find', data
      $scope.tokens = data
      $scope.query = {}
      $scope.hideSearchTokenForm()
    return

  $scope.editToken = (index, id) ->
    console.log 'edit token', index, id
    $scope.tokenIndex = index
    Tokens = Api.bind first: clientId, second: 'ids', third: 'list'
    Tokens.postArray ids:[id], (data) ->
      console.log 'get one token', data
      $scope.token = dataToString data
      $scope.formToken = true
      return
    return

  $scope.removeToken = (index, id) ->
    Tokens = Api.bind first: clientId, second: 'ids', third: 'delete'
    Tokens.post ids:[id], (data) ->
        $scope.tokens.splice index, 1
        console.log 'remove token', data
      return
    return

  $scope.updateTokens = ->
    arrayToken = dataToArray $scope.token
    console.log 'update token', $scope.tokenIndex, $scope.token, arrayToken
    Tokens = Api.bind first: clientId, second: 'ids'
    Tokens.put arrayToken, (data) ->
      console.log 'put tokens', arrayToken
      $scope.tokens[$scope.tokenIndex] =
        id: arrayToken.ids[0]
        tags: arrayToken.tags
      arrayToken.ids.splice 0, 1
      for i of arrayToken.ids
        $scope.tokens.push
          id: arrayToken.ids[i]
          tags: arrayToken.tags
      $scope.hideTokenForm()
    return

  $scope.createTokens = ->
    arrayToken = dataToArray $scope.token
    Tokens = Api.bind first: clientId, second: 'ids'
    Tokens.post arrayToken, (data) ->
      for i of arrayToken.ids
        $scope.tokens.push
          id: arrayToken.ids[i]
          tags: arrayToken.tags
      $scope.hideTokenForm()
    return

  $scope.switchTargetTags = ->
    $scope.targetTokens = false
    $scope.targetTags = true
    return

  $scope.switchTargetTokens = ->
    $scope.targetTokens = true
    $scope.targetTags = false
    return

  $scope.switchTargetTags()

  return
]

pushApp.controller 'tagsController', ['$scope', '$rootScope', '$routeParams', 'Api', 'Utils', ($scope, $rootScope, $routeParams, Api, Utils) ->
  console.log 'tags'

  clientId = $rootScope["client_id"] = $routeParams["client_id"]

  $scope.query = {}

  Clients = Api.bind first: 'client', second: clientId
  client = Clients.getOne ->
    console.log 'client', client
    $scope.client = client
    return

  $scope.addTags = ->
    console.log 'delete tags', $scope.query, $scope.tags
    send = {}
    send.q = Utils.prepareQuery $scope.query.q
    send.tags = Utils.tagsToArray $scope.tags.add
    Tokens = Api.bind first: clientId, second: 'ids', third: 'tag'
    Tokens.post send, (data) ->
      console.log 'send add', data
      $scope.tags.add = ''
      return
    return

  $scope.deleteTags = ->
    console.log 'delete tags', $scope.query, $scope.tags
    send = {}
    send.q = Utils.prepareQuery $scope.query.q
    send.tags = Utils.tagsToArray $scope.tags.delete
    Tokens = Api.bind first: clientId, second: 'ids', third: 'tag', fourth: 'delete'
    Tokens.post send, (data) ->
      console.log 'send delete', data
      $scope.tags.delete = ''
      return
    return

  $scope.replaceTag = ->
    console.log 'replace tags', $scope.query, $scope.tags
    send = {}
    send.q = Utils.prepareQuery $scope.query.q
    send.old = $scope.tags.old
    send.new = $scope.tags.new
    Tokens = Api.bind first: clientId, second: 'ids', third: 'tag', fourth: 'replace'
    Tokens.put send, (data) ->
      console.log 'send replace', data
      $scope.tags.old = ''
      $scope.tags.new = ''
      return
    return

  $scope.switchTargetTags = ->
    $scope.targetTokens = false
    $scope.targetTags = true
    return

  $scope.switchTargetTokens = ->
    $scope.targetTokens = true
    $scope.targetTags = false
    return

  $scope.switchTargetTags()

  return
]

pushApp.controller 'pushesController', ['$scope', '$rootScope', '$routeParams', 'Api', 'Utils', ($scope, $rootScope, $routeParams, Api, Utils) ->

  console.log 'pushes'
  clientId = $rootScope["client_id"] = $routeParams["client_id"]

  $scope.query = {}

  defaultPush = appConfig["gcm"].defaultPush

  # debug form
  #$scope.push = defaultPush
  #$scope.formPush = true;

  $scope.addDataField = ->
    $scope.push.data.push key:"", value:""
    return

  $scope.removeDataField = (index) ->
    $scope.push.data.splice index, 1
    return

  $scope.switchTargetTags = ->
    $scope.targetTokens = false
    $scope.targetTags = true
    return

  $scope.switchTargetTokens = ->
    $scope.targetTokens = true
    $scope.targetTags = false
    return

  Clients = Api.bind first: 'client', second: clientId
  client = Clients.getOne ->
    console.log 'client', client
    $scope.client = client
    return

  limit = appConfig.paging.limit
  Pushes = Api.bind first: clientId, second: 'push'
  _pushes = Pushes.get limit:1000, ->
    pushes = {}
    console.log 'pushes', _pushes
    for i of _pushes
      pushes[_pushes[i].id] = _pushes[i]
    $scope.pushes = pushes
    return

  $scope.updateStatus = (id) ->
    Pushes = Api.bind first: clientId, second: 'push', third: id
    status = Pushes.getOne ->
      $scope.pushes[id] = status
      return

  $scope.newPush = ->
    $scope.push = defaultPush
    $scope.formPush = true;
    return

  $scope.hidePushForm = ->
    $scope.formPush = false
    return

  $scope.sendPush = ->
    console.log 'sendPush', $scope.push
    send = {}
    send.data = {}
    for i of $scope.push.data
      send.data[$scope.push.data[i].key] = $scope.push.data[i].value
    send.q = Utils.prepareQuery $scope.query.q
    if $scope.push['delay_while_idle']
      send['delay_while_idle'] = $scope.push['delay_while_idle']
    if $scope.push.ttl
      send.ttl = $scope.push.ttl
    if $scope.push['package_name']
      send['package_name'] = $scope.push['package_name']

    console.log 'send', send

    Pushes = Api.bind first: clientId, second: 'push', third: 'gcm'
    Pushes.post send, (data) ->
      console.log 'send push', data
      $scope.pushes[data.id] = data
      $scope.formPush = false
      return

  $scope.pushPercent = (status) ->
    console.log 'push', status
    return ((100 * status.progress) / status.count).toFixed(2) if status and status.count > 0
    "0"


  $scope.switchTargetTags()

  return
]
