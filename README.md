# Noost

Simple bootstrapping tool for PHP web development using modern tools.

## Requirements

* [Composer](https://getcomposer.org/)

## Why is it named Noost?

Name come from words `Nette` and `boost` since it is tool primary designed for Nette framework.

## What does it do?

1. Create project folder
2. Install some composer package there (optional)
3. Make `log` and `temp` folders writable if they exist (optional | default with `nette/web-project` package)
4. Create front-end folders (work in progress)
5. Set up a virtual host. It adds `<project_name>.l` URL to `/etc/hosts` and adds record to Apache configuration file (default: `/etc/apache2/sites-enabled/localhost-site.conf`)


## Usage

```
Usage: ./noost.sh [options] <project_path> <project_name>

Available options:
    -a <path>                Apache configuration file path (default: /etc/apache2/sites-enabled/localhost-site.conf)
    -c <package_name>        composer web project package
    -n                       creates Standard Nette Web Project
    -w                       make 'log' and 'temp' folders writable
    -h                       displays help
```

## Roadmap

* Multiple frontend projects (eg. front and admin)
* Move temporary/development files out of `www` directory because they can be accessed on production server
* Separate styles to separate git repository/module
* Utilize [Yeoman](http://yeoman.io/)
