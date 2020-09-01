[![Build Status](https://travis-ci.org/patrickbr/hagel.svg?branch=master)](https://travis-ci.org/patrickbr/hagel)

hagel
=====

An static page generator that supports multiple languages, templating, two-level menus, content categories (_"content types"_) and direct rendering of system command outputs into content.

Implemented in a single ~200 LOC Makefile. Created during [a heavy hail storm in may 2015](https://www.youtube.com/watch?v=HDuHtCnxxj8), hence the name (hagel means hail in german). Mostly meant as a joke to make fun of heavy-weight web frameworks.

An example page rendered with hagel [can be found here](http://patrickbrosi.de/hagelexample).

My [own homepage](http://patrickbrosi.de) is also rendered with hagel.

Who is this for?
================

You may find this useful if

 * you are building a website (_not_ a web application)
 * you are familiar with writing HTML, CSS and JS by hand
 * you think that many static page generators, most web frameworks and especially most CMS are too heavyweight for simple websites
 * you think that content that won't change for months shouldn't be rendered on each request

What does it do?
================

hagel lets you create template files for the overall page, categories, content and the menu. The structure of the website is defined as a directory hierarchy. Languages, categories and content are described as `*.info` files in which variables can be defined. These variables can be accessed in the template files. Since variables are expanded two times and can include direct output of system calls, this allows for quite elaborate setups.

Prerequisites
=============

You should have `make` installed. On debianesque systems, type

    apt-get install make

to install it.

The following commands are used and should be either installed as binaries or provided as built-in functions of your shell:

    find, test, GNU sed, tr, cp, cat, rm, mkdir, touch, printf

If you are running a unix-like system, you shouldn't have to worry about them. Please note, however, that hagel makes use of some GNU extensions to `sed`. If you have a version of `sed` installed that only supports posix style parameters, you won't be able to use hagel.

Usage
=====

A repo for an example page using a bootstrap base theme [can be found here](https://github.com/patrickbr/hagel-example).

A very simple example page is included in this repository (in `./content`). You can build it by typing 

    make

After the build has finished, you should be able to open `./html/index.html` with your favorite webbrowser. By default, hagel uses the absolute file system path of `index.html` files to follow links. If you want to move the site to a live web server and your webserver automatically displays `index.html` files if directories are queried, you can adjust the base and index path by setting BASE, for example like this:

    make BASE='/' INDEX=''

For a more thorough explanation of the build process parameters, see below.

Template files
--------------

Template files are in `./templates`. You can modify them and run `make` again to see changes. There are 6 types of template files which are presented here in hierarchical order. See the comments in the `./template` files for a list of variables that are accessible in them

 * `page.tmpl`, a template file for the overall page
 * `category_menu_row.tmpl`, a template file for a single category entry in the menu. You can insert the special variable `$submenu{}` anywhere in this file. It will be replaced with 2ndary menu (a list of content in this category, visible if a user is inside a content in this category)
 * `content_menu_row.tmpl`, the template file for a single _content_ entry in the 2ndary menu
 * `lan_switch_row.tmpl`, a template file for a single entry in the language switcher
 * `category.tmpl`, a template file for category pages (pages which offer a list of content teasers)
 * `content_row.tmpl`, a template file for a content row inside a category page (is used to render the 'teaser' of a content)
 * `content.tmpl`, a template file for full content

Template files can be overwritten by placing them inside a category folder in `./content`. See below for more information on that.

Be default, hagel uses the template found in `./template`. If you are for example using several templates in different directories, you can set TEMPLATE to a different path in your `make` call like this:

    make TEMPLATE='my-shiny-new-template'

Categories
----------

Categories appear in the menu and can either be used as simple content pages (if you have a simple one-level page layout) or as a way to group content together. In the `category.tmpl` file, you have access to the special `$rows{}` variable that renders each `*.content` file found in the category folder into a teaser list.

A category must have a `category.info` file in its directory. You can define variables there at will (variable names may contain letters, numbers, _ and -). Each variable defined in `category.info` can be accessed in the `category.tmpl` file by writing

    $category{<VARIABLE NAME>}

You are free to add, for example, a short introdution to a category be defining a variable like `MY_INTRO` in the category.info and rendering it in `category.tmpl` like this:

    <div class="cat-intro">
         $category{MY_INTRO}
    </div>

Categories offer the special WEIGHT variable which defines the order a category is rendered in the menu. Lower weight means it appears earlier in the menu. 

Content
-------

Content is defined per category and is stored in `*.content` files. Have a look at the examples to see how variables for the full and teaser contents are defined.

Just like `category.info` files, `*.content` files offer the `WEIGHT` variable which defines the order content rows are rendered in the category's teaser list.

Overwriting template files in categories
----------------------------------------

You can override certain template files (`page.tmpl`, `category.tmpl`, `content.tmpl` and `content_row.tmpl`) per category. Just add the file to the category folder. It will be used in the rendering process for that category.

Static files
------------

Static files are not part of the rendered HTML content. Be default, they are placed in `./static` and the `$global{STATIC_PATH}` variable is filed with the absolute file system path of `./static`. However, if you are deploying your application to a live webserver, you should define the path static files will be reachable from the site during the build process like described below.

Building
--------

The general build command is

    make

or

    make all

which has to be executed in the base folder of this repository. It only re-renders those parts of the website that have changed since the last build.

If you want to rebuild the page completely, you can either run

    make !

or

    make all!

or

    make clean && make

The clean target removes every rendered file.

By default, hagel renders the HTML for direct file system access through the browser. However, this is most likely not what you want.

Three parameters have to be configured if you are planning to deploy the website to a live server:

* `BASE` the base path used for the entire website. If you set `BASE` to `/`, a link to `en/main/` will for example be rendered as `/en/main`, or `http://mysite.com/en/main` if you set `BASE` to `http://mysite.com/`.
* `INDEX` the path that is used to access indexes. By default, this is set to `/index.html`. If your web server delivers `index.html` automatically on directory requests (like most web servers do), you can set this to `/`.
* `STATIC` this is mostly for your own use through `$glocal{STATIC_PATH}`. It should contain the path at which the web browser can access static files on your server.

To render a site which can be access directly via the `/` endpoint on a server that delivers `index.html` automatically and which holds static files at `/static`, run this command:

    make BASE=/ INDEX=/ STATIC=/static/

Known restrictions
==================

Paging
------

There is no paging for content rows. This is the next big thing that has to be implemented.

Error messages
--------------

Error messages are for the most part cryptic errors from `sed`. Most of them are entirely useless to you.

Alpha status
------------

Hagel is a mere hobby project and is still in experimental alpha status. Please report any bugs :)

License
=======

GPL v2
