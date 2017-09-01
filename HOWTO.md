How to notes
===

## Goal

Use the [Gunicorn](http://gunicorn.org/) WSGI HTTP server to serve your application.

### Basic information

#### About Openshift

* The Gunicorn WSGI HTTP server is used to serve your application in the case that it is installed
    - The easiest way to install gunicorn fixing desired version is using the `requirements.txt`
    - At the moment using `setup.py` strategy breaks installation raising [this exception](installing-gunicorn-using-setup.log):

        ```
        File "build/bdist.linux-x86_64/egg/gunicorn/workers/_gaiohttp.py", line 84
          yield from self.wsgi.close()
                   ^
        SyntaxError: invalid syntax
        ```    

* If a file named **wsgi.py** is present in your repository, it will be used by Gunicorn
    as the entry point to your application.

* Useful environment variables:
    * **HOME** : The path of your user account (i.e. `/opt/app-root/src`);
        Equivalent to the variable _OPENSHIFT_PYTHON_DIR_ in the Openshift v.2 env.

#### About web2py

* Instantiating an application from the web2py [appfactory](https://github.com/web2py/web2py/blob/R-2.14.6/gluon/main.py#L604)
    keep in mind that:
    * you have to valorize the `web2py_path` environment variable. Eg.:
        ```python
        os.environ['web2py_path'] = os.path.join(os.environ['HOME'], 'wsgi', 'web2py')
        ```
    * the framework path must contains the `site-packages` directory
        > NOTE:
        > The `site-packages` directory is not copied during the [minification](http://web2py.com/books/default/chapter/29/14/other-recipes#Building-a-minimalist-web2py).

## File system structure

```
+-- <this>
|   +-- wsgi
|   |   +-- web2py
|   +-- setup.py
|   +-- requirements.py
|   +-- wsgi.py
|   +-- ...
```

References
===

* [Python Docker image README](https://github.com/sclorg/s2i-python-container/blob/master/2.7/README.md)
    - [Python Docker image _Run Strategies_ ](https://github.com/sclorg/s2i-python-container/blob/master/2.7/README.md#run-strategies)
