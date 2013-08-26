# Push Service Web Client  
Client build with `angular.js 1.0.7`, `bootstrap 3.0`  
Using preprocessors `jade`, `coffeescript`, `stylus`  
Preprocessor manager `jastyco`  

### Requires
```
node.js, npm
```

### Install
```
npm install jastyco -g
jastyco -b # for build from source directory
cp dest/static/js/app-config.example.js dest/static/js/app-config.js
# or copy src/static/js/app-config.example.coffee to src/static/js/app-config.coffee
# modify dest/static/js/app-config.js or src/static/js/app-config.coffee
# open `dest/index.html` in browser
done
```

### Description
* `src` - source directory
* `dest` - destination directory
* `dest/index.html` - web entry point
* `dest/static/js/app-config.js` - app config file
* `jastyco.json` - jastyco config file
* `vendors` - angular, bootstrap, etc..

### Usage
```
jastyco -b # for build from source directory
jastyco # watch and compile changed files
```
