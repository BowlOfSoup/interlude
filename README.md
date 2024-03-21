## Interlude
### Purpose and functionality
Use this within your PHP [Composer](https://getcomposer.org/) project to develop locally
on packages. 

* Packages are cloned into a separate directory 
* Symlinked to the original vendor/ location 
* Use `git` without it being in detached mode, e.g. to create new branches for the package
* You can use `composer require` to e.g. add dependencies (vendor dir is also symlinked to the original) 

### Installation
Require the package:
```
composer require bowlofsoup/interlude "^version"
```

The `interlude` script should now be in your `vendor/bin` directory.

Add the following to your `.gitignore`:

```
vendor-local/
```

### Usage
'Checkout' a package for local development (use `sh`)
```
sh vendor/bin/interlude checkout <package>
```

'Restore' a package to the original
```
vendor/bin/interlude restore <package>
```

### External dependencies
A shell (Bash) and these Linux or macOS packages:
* `git`
* `find`
* `sed`
* `awk`
